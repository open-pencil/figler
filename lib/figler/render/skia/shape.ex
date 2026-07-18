defmodule Figler.Render.Skia.Shape do
  @moduledoc false
  @compile {:no_warn_undefined, [Skia]}

  alias Figler.Render.Node
  alias Figler.Render.Skia.Paint

  @rectangular_types [:frame, :instance, :rectangle, :rounded_rectangle, :section, :symbol]
  @supported_types @rectangular_types ++ [:boolean_operation, :ellipse, :line, :text, :vector]

  @spec supported_type?(String.t()) :: boolean()
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
         %Node{node_type: :text, text: text, size: size},
         _kind,
         opts,
         _assets
       ) do
    text_opts = [
      x: 0,
      y: 0,
      size: text.font.size || 14,
      font_family: text.font.family || "Arial",
      fill: Keyword.get(opts, :fill, Keyword.get(opts, :stroke, :black))
    ]

    text_opts = if size, do: Keyword.put(text_opts, :width, size.x), else: text_opts
    Skia.text(document, text.content, text_opts)
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

  defp geometry_paths(assets, node, kind) do
    assets.geometries
    |> Map.get(node.guid, %{})
    |> Map.get(kind, [])
  end

  defp geometry_paint_opts(opts, :fill), do: opts
  defp geometry_paint_opts(opts, :stroke), do: [fill: Keyword.get(opts, :stroke, :black)]
end
