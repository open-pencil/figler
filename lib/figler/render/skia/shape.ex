defmodule Figler.Render.Skia.Shape do
  @moduledoc false
  @compile {:no_warn_undefined, [Skia, Skia.TextSpan]}

  alias Figler.Render.Node
  alias Figler.Render.Skia.Paint

  @rectangular_types [:frame, :instance, :rectangle, :rounded_rectangle, :section, :symbol]
  @supported_types @rectangular_types ++ [:boolean_operation, :ellipse, :line, :text, :vector]

  @spec supported_type?(Figler.Schema.NodeType.t() | :unknown) :: boolean()
  def supported_type?(type), do: type in @supported_types

  @spec visible_paints?(Node.t()) :: boolean()
  def visible_paints?(node) do
    Enum.any?([node.fill_paints || [], node.stroke_paints || []], fn paints ->
      Enum.any?(paints, &(Map.get(&1, :visible) != false))
    end)
  end

  @spec draw_node(Skia.Document.t(), Node.t(), map()) :: Skia.Document.t()
  def draw_node(document, node, assets) do
    document = Enum.reduce(node.fill_paints || [], document, &draw_fill(&2, node, &1, assets))
    weight = node.stroke_weight || 1
    Enum.reduce(node.stroke_paints || [], document, &draw_stroke(&2, node, &1, weight, assets))
  end

  defp draw_fill(document, node, paint, assets) do
    case Paint.resolve(paint, node.size, assets.images) do
      {:ok, resolved} ->
        draw_resolved(document, node, :fill, [fill: resolved.paint], resolved, assets)

      {:error, _reason} ->
        document
    end
  end

  defp draw_stroke(
         document,
         %Node{node_type: node_type},
         %{type: paint_type},
         _weight,
         _assets
       )
       when node_type not in [:vector, :boolean_operation] and paint_type != :solid,
       do: document

  defp draw_stroke(document, node, paint, weight, assets) do
    case Paint.resolve(paint, node.size, assets.images) do
      {:ok, resolved} ->
        opts = [stroke: resolved.paint, stroke_width: weight]
        draw_resolved(document, node, :stroke, opts, resolved, assets)

      {:error, _reason} ->
        document
    end
  end

  defp draw_resolved(document, node, kind, opts, %{opacity: opacity}, assets)
       when is_number(opacity) and opacity < 1 do
    Skia.layer(document, [opacity: opacity], &draw_shape(&1, node, kind, opts, assets))
  end

  defp draw_resolved(document, node, kind, opts, _resolved, assets),
    do: draw_shape(document, node, kind, opts, assets)

  defp draw_shape(document, %Node{node_type: type} = node, kind, opts, assets)
       when type in [:vector, :boolean_operation] do
    paths = geometry_paths(assets, node, kind)
    path_opts = geometry_paint_opts(opts, kind)

    Enum.reduce(paths, document, fn geometry, rendered ->
      Skia.path(rendered, geometry.path, Keyword.put(path_opts, :fill_rule, geometry.fill_rule))
    end)
  end

  defp draw_shape(
         document,
         %Node{node_type: :ellipse, size: size},
         _kind,
         opts,
         _assets
       ),
       do: Skia.oval(document, Keyword.merge([x: 0, y: 0, width: size.x, height: size.y], opts))

  defp draw_shape(document, %Node{node_type: :line, size: size}, _kind, opts, _assets) do
    Skia.line(document,
      from: {0, 0},
      to: {size.x, size.y},
      stroke: Keyword.get(opts, :stroke, Keyword.get(opts, :fill, :black)),
      stroke_width: Keyword.get(opts, :stroke_width, 1)
    )
  end

  defp draw_shape(
         document,
         %Node{node_type: :text, text: text, size: size} = node,
         _kind,
         opts,
         assets
       ) do
    inherited_fill = Keyword.get(opts, :fill, Keyword.get(opts, :stroke, :black))
    text_opts = [x: 0, y: 0, size: text.font.size || 14, fill: inherited_fill]
    text_opts = if size, do: Keyword.put(text_opts, :width, size.x), else: text_opts

    if rich_text?(text) do
      spans = Enum.map(text.runs, &text_span(&1, node, assets, inherited_fill))

      text_opts =
        text_opts |> Keyword.put(:spans, spans) |> register_span_font(node, text, assets)

      Skia.text(document, "", text_opts)
    else
      run = List.first(text.runs)
      resolved = run && Map.get(assets.fonts, {node.guid, run.index})
      text_opts = text_font_opts(text_opts, (run && run.font) || text.font, resolved)
      Skia.text(document, text.content, text_opts)
    end
  end

  defp draw_shape(
         document,
         %Node{node_type: type, size: %{x: width, y: height}} = node,
         _kind,
         opts,
         _assets
       )
       when type in @rectangular_types do
    Skia.rect(
      document,
      Keyword.merge(
        [x: 0, y: 0, width: width, height: height, radius: node.corner_radius || 0],
        opts
      )
    )
  end

  defp draw_shape(document, _node, _kind, _opts, _assets), do: document

  defp rich_text?(%{runs: [_, _ | _]}), do: true
  defp rich_text?(text), do: Enum.any?(text.runs, &(&1.style_id != 0))

  defp text_span(run, node, assets, inherited_fill) do
    resolved = Map.get(assets.fonts, {node.guid, run.index})

    span_opts =
      [size: run.font.size || text_size(node), fill: run_fill(run, node, assets, inherited_fill)]
      |> text_font_opts(run.font, resolved)

    Skia.TextSpan.new(run.content, span_opts)
  end

  defp text_size(%Node{text: text}), do: text.font.size || 14

  defp run_fill(%{fill_override?: false}, _node, _assets, inherited), do: inherited

  defp run_fill(run, node, assets, inherited) do
    case Enum.find(run.fill_paints, &(&1.visible != false and &1.type == :solid)) do
      nil ->
        inherited

      paint ->
        case Paint.resolve(paint, node.size, assets.images) do
          {:ok, resolved} -> resolved.paint
          {:error, _reason} -> inherited
        end
    end
  end

  defp register_span_font(opts, node, text, assets) do
    # Skia's paragraph provider registers the top-level loaded font. Prefer the
    # supplied span serving non-ASCII glyphs; explicit span typefaces retain the
    # remaining run styles.
    registration =
      text.runs
      |> Enum.map(&{&1, Map.get(assets.fonts, {node.guid, &1.index})})
      |> Enum.filter(fn {_run, resolved} -> resolved && resolved.source == :supplied end)
      |> Enum.max_by(fn {run, _resolved} -> non_ascii_count(run.content) end, fn -> nil end)

    case registration do
      {_run, resolved} -> Keyword.put(opts, :font, resolved.font)
      nil -> opts
    end
  end

  defp non_ascii_count(content), do: Enum.count(String.to_charlist(content), &(&1 > 0x7F))

  defp text_font_opts(opts, font, nil),
    do: Keyword.put(opts, :font_family, font.family || "Arial")

  defp text_font_opts(opts, _font, resolved),
    do: Keyword.put(opts, :font, resolved.font)

  defp geometry_paths(assets, node, kind) do
    assets.geometries
    |> Map.get(node.guid, %{})
    |> Map.get(kind, [])
  end

  defp geometry_paint_opts(opts, :fill), do: opts
  defp geometry_paint_opts(opts, :stroke), do: [fill: Keyword.get(opts, :stroke, :black)]
end
