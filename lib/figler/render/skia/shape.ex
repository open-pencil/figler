defmodule Figler.Render.Skia.Shape do
  @moduledoc false
  @compile {:no_warn_undefined, [Skia, Skia.PathEffect, Skia.TextSpan]}

  alias Figler.Render.Node
  alias Figler.Render.Skia.Paint
  alias Figler.Render.Stroke

  @rectangular_types [:frame, :instance, :rectangle, :rounded_rectangle, :section, :symbol]
  @stroke_alignment_types @rectangular_types ++ [:boolean_operation, :ellipse, :vector]
  @effect_shape_types @stroke_alignment_types ++ [:text]
  @supported_types @effect_shape_types ++ [:line]

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
    stroke = node.stroke || %Stroke{}
    Enum.reduce(node.stroke_paints || [], document, &draw_stroke(&2, node, &1, stroke, assets))
  end

  @doc false
  @spec stroke_alignment_supported?(Node.t() | map()) :: boolean()
  def stroke_alignment_supported?(%{node_type: type}), do: type in @stroke_alignment_types

  @doc false
  @spec effect_shape_supported?(Node.t() | map()) :: boolean()
  def effect_shape_supported?(%{node_type: type}), do: type in @effect_shape_types

  @doc false
  @spec draw_silhouette(Skia.Document.t(), Node.t(), map(), keyword(), keyword()) ::
          Skia.Document.t()
  def draw_silhouette(document, node, assets, opts, effect_opts \\ [])

  def draw_silhouette(
        document,
        %Node{node_type: type, size: %{x: width, y: height}} = node,
        _assets,
        opts,
        effect_opts
      )
      when type in @rectangular_types do
    inset = Keyword.get(effect_opts, :inset, 0.0)
    radius = max((node.corner_radius || 0.0) - inset, 0.0)

    Skia.rect(document,
      x: inset,
      y: inset,
      width: max(width - inset * 2, 0.0),
      height: max(height - inset * 2, 0.0),
      radius: radius,
      fill: Keyword.get(opts, :fill, :white),
      blend_mode: Keyword.get(opts, :blend_mode, :src_over)
    )
  end

  def draw_silhouette(
        document,
        %Node{node_type: :ellipse, size: %{x: width, y: height}},
        _assets,
        opts,
        effect_opts
      ) do
    inset = Keyword.get(effect_opts, :inset, 0.0)

    Skia.oval(document,
      x: inset,
      y: inset,
      width: max(width - inset * 2, 0.0),
      height: max(height - inset * 2, 0.0),
      fill: Keyword.get(opts, :fill, :white),
      blend_mode: Keyword.get(opts, :blend_mode, :src_over)
    )
  end

  def draw_silhouette(
        document,
        %Node{node_type: type} = node,
        assets,
        opts,
        _effect_opts
      )
      when type in [:vector, :boolean_operation] do
    assets
    |> geometry_paths(node, :fill)
    |> Enum.reduce(document, fn geometry, rendered ->
      path_opts =
        opts
        |> Keyword.put_new(:fill, :white)
        |> Keyword.put(:fill_rule, geometry.fill_rule)

      Skia.path(rendered, geometry.path, path_opts)
    end)
  end

  def draw_silhouette(
        document,
        %Node{node_type: :text, text: text, size: size} = node,
        assets,
        opts,
        _effect_opts
      ) do
    fill = Keyword.get(opts, :fill, :white)

    text_opts = [
      x: 0,
      y: 0,
      size: text.font.size || 14,
      fill: fill,
      blend_mode: Keyword.get(opts, :blend_mode, :src_over)
    ]

    text_opts = text_layout_opts(text_opts, text, size)
    spans = Map.get(assets.font_spans, node.guid, [])

    if rich_text?(spans) do
      skia_spans = Enum.map(spans, &silhouette_text_span(&1, node, assets, fill))
      Skia.text(document, "", Keyword.put(text_opts, :spans, skia_spans))
    else
      span = List.first(spans)

      text_opts =
        text_opts
        |> text_font_opts((span && span.font) || text.font, span && span.resolved)
        |> typography_opts(span, node, assets)

      Skia.text(document, text.content, text_opts)
    end
  end

  def draw_silhouette(document, _node, _assets, _opts, _effect_opts), do: document

  defp silhouette_text_span(span, node, assets, fill) do
    span_opts =
      [size: span.font.size || text_size(node), fill: fill]
      |> text_font_opts(span.font, span.resolved)
      |> typography_opts(span, node, assets)

    Skia.TextSpan.new(span.content, span_opts)
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
         _stroke,
         _assets
       )
       when node_type not in [:vector, :boolean_operation] and paint_type != :solid,
       do: document

  defp draw_stroke(document, node, paint, stroke, assets) do
    case Paint.resolve(paint, node.size, assets.images) do
      {:ok, resolved} ->
        opts = stroke_opts(resolved.paint, stroke)
        draw_resolved_stroke(document, node, opts, resolved, assets, stroke)

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

  defp draw_resolved_stroke(document, node, opts, resolved, assets, stroke)
       when stroke.align in [:inside, :outside] do
    if stroke_alignment_supported?(node) do
      draw_aligned_stroke(document, node, opts, resolved, assets, stroke)
    else
      draw_resolved(document, node, :stroke, opts, resolved, assets)
    end
  end

  defp draw_resolved_stroke(document, node, opts, resolved, assets, _stroke),
    do: draw_resolved(document, node, :stroke, opts, resolved, assets)

  defp draw_aligned_stroke(document, node, opts, resolved, assets, stroke) do
    weight = stroke.weight || 1.0
    bounds = {-weight, -weight, node.size.x + weight * 2, node.size.y + weight * 2}
    doubled_opts = Keyword.put(opts, :stroke_width, weight * 2)
    mask_blend = if stroke.align == :inside, do: :dst_in, else: :dst_out

    Skia.layer(document, [bounds: bounds], fn isolated ->
      mask_aligned_stroke(isolated, node, doubled_opts, resolved, assets, bounds, mask_blend)
    end)
  end

  defp mask_aligned_stroke(isolated, node, opts, resolved, assets, bounds, mask_blend) do
    isolated = draw_resolved(isolated, node, :stroke, opts, resolved, assets)

    Skia.layer(isolated, [bounds: bounds, blend_mode: mask_blend], fn mask ->
      draw_silhouette(mask, node, assets, fill: :white)
    end)
  end

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
    line_opts =
      Keyword.merge(
        [from: {0, 0}, to: {size.x, size.y}],
        line_paint_opts(opts)
      )

    Skia.line(document, line_opts)
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
    text_opts = text_layout_opts(text_opts, text, size)

    spans = Map.get(assets.font_spans, node.guid, [])

    if rich_text?(spans) do
      skia_spans = Enum.map(spans, &text_span(&1, node, assets, inherited_fill))
      Skia.text(document, "", Keyword.put(text_opts, :spans, skia_spans))
    else
      span = List.first(spans)

      text_opts =
        text_opts
        |> text_font_opts((span && span.font) || text.font, span && span.resolved)
        |> typography_opts(span, node, assets)

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

  defp line_paint_opts(opts) do
    if Keyword.has_key?(opts, :stroke) do
      opts
    else
      opts
      |> Keyword.put(:stroke, Keyword.get(opts, :fill, :black))
      |> Keyword.put_new(:stroke_width, 1)
      |> Keyword.delete(:fill)
    end
  end

  defp rich_text?([_, _ | _]), do: true
  defp rich_text?(spans), do: Enum.any?(spans, &(&1.style_id != 0))

  defp text_span(span, node, assets, inherited_fill) do
    span_opts =
      [
        size: span.font.size || text_size(node),
        fill: run_fill(span, node, assets, inherited_fill)
      ]
      |> text_font_opts(span.font, span.resolved)
      |> typography_opts(span, node, assets)

    Skia.TextSpan.new(span.content, span_opts)
  end

  defp text_size(%Node{text: text}), do: text.font.size || 14

  defp text_layout_opts(opts, _text, nil), do: opts

  defp text_layout_opts(opts, text, size) do
    opts
    |> Keyword.put(:width, size.x)
    |> Keyword.put(:height, size.y)
    |> put_option(:align, horizontal_align(text.align_horizontal))
    |> put_option(:vertical_align, text.align_vertical)
    |> put_option(:max_lines, max_lines(text, size))
    |> put_option(:ellipsis, ellipsis(text.truncation))
  end

  defp horizontal_align(:justified), do: :justify
  defp horizontal_align(align) when align in [:left, :center, :right], do: align
  defp horizontal_align(_align), do: nil

  defp max_lines(%{max_lines: value}, _size) when is_integer(value) and value > 0, do: value

  defp max_lines(%{truncation: :ending, runs: [run | _], font: font}, %{y: height}) do
    line_height = run.line_height || (font.size || 14) * 1.2
    max(1, floor(height / line_height))
  end

  defp max_lines(_text, _size), do: nil

  defp ellipsis(:ending), do: "…"
  defp ellipsis(_truncation), do: nil

  defp typography_opts(opts, nil, _node, _assets), do: opts

  defp typography_opts(opts, span, node, assets) do
    opts
    |> put_option(:line_height, span.line_height)
    |> put_option(:letter_spacing, span.letter_spacing)
    |> put_option(:decoration, decoration(span.text_decoration))
    |> put_option(:decoration_style, span.text_decoration_style)
    |> put_option(:decoration_mode, decoration_mode(span.text_decoration_skip_ink))
    |> put_option(:decoration_color, decoration_color(span, node, assets))
  end

  defp decoration(:underline), do: :underline
  defp decoration(:strikethrough), do: :line_through
  defp decoration(_decoration), do: nil

  defp decoration_mode(true), do: :gaps
  defp decoration_mode(false), do: :through
  defp decoration_mode(nil), do: nil

  defp decoration_color(span, node, assets) do
    case Enum.find(
           span.text_decoration_fill_paints,
           &(&1.visible != false and &1.type == :solid)
         ) do
      nil -> nil
      paint -> paint |> Paint.resolve(node.size, assets.images) |> resolved_paint()
    end
  end

  defp resolved_paint({:ok, resolved}), do: resolved.paint
  defp resolved_paint({:error, _reason}), do: nil

  defp put_option(opts, _key, nil), do: opts
  defp put_option(opts, key, value), do: Keyword.put(opts, key, value)

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

  defp text_font_opts(opts, font, nil),
    do: Keyword.put(opts, :font_family, font.family || "Arial")

  defp text_font_opts(opts, _font, resolved),
    do: Keyword.put(opts, :font, resolved.font)

  defp geometry_paths(assets, %{vector_network: reference} = node, kind)
       when not is_nil(reference) do
    assets.vector_geometries
    |> Map.get(node.guid, %{})
    |> Map.get(kind, [])
  end

  defp geometry_paths(assets, node, kind) do
    assets.geometries
    |> Map.get(node.guid, %{})
    |> Map.get(kind, [])
  end

  defp stroke_opts(paint, stroke) do
    [stroke: paint, stroke_width: stroke.weight || 1]
    |> put_option(:stroke_cap, Stroke.skia_cap(stroke))
    |> put_option(:stroke_join, stroke.join)
    |> put_option(:stroke_miter, stroke_miter(stroke.miter_limit))
    |> put_dash_pattern(stroke)
  end

  defp stroke_miter(value) when is_number(value) and value > 0, do: value
  defp stroke_miter(_value), do: nil

  defp put_dash_pattern(opts, %Stroke{dash_pattern: []}), do: opts

  defp put_dash_pattern(opts, %Stroke{} = stroke) do
    if Stroke.valid_dash_pattern?(stroke),
      do: Keyword.put(opts, :path_effect, Skia.PathEffect.dash(stroke.dash_pattern)),
      else: opts
  end

  defp geometry_paint_opts(opts, :fill), do: opts
  defp geometry_paint_opts(opts, :stroke), do: opts
end
