defmodule Figler.Render.Skia.Shape do
  @moduledoc false
  @compile {:no_warn_undefined, [Skia, Skia.Path, Skia.PathEffect, Skia.TextSpan]}

  alias Figler.Render.CornerRadii
  alias Figler.Render.Node
  alias Figler.Render.Shape, as: PrimitiveShape
  alias Figler.Render.Shape.Arc
  alias Figler.Render.Shape.Polygon
  alias Figler.Render.Shape.Star
  alias Figler.Render.Skia.Paint
  alias Figler.Render.Stroke
  alias Figler.Render.Text.Glyphs

  @rectangular_types [:frame, :instance, :rectangle, :rounded_rectangle, :section, :symbol]
  @primitive_path_types [:regular_polygon, :star]
  @stroke_alignment_types @rectangular_types ++
                            @primitive_path_types ++ [:boolean_operation, :ellipse, :vector]
  @text_types [:text, :text_path]
  @effect_shape_types @stroke_alignment_types ++ @text_types
  @supported_types @effect_shape_types ++ [:line]

  @spec supported_type?(Figler.Schema.NodeType.t() | :unknown) :: boolean()
  def supported_type?(type), do: type in @supported_types

  @doc false
  @spec issues(Node.t()) :: [map()]
  def issues(%Node{shape: shape, corners: %CornerRadii{} = corners}) do
    PrimitiveShape.issues(shape) ++ CornerRadii.warnings(corners)
  end

  def issues(%Node{shape: shape}), do: PrimitiveShape.issues(shape)

  @spec visible_paints?(Node.t()) :: boolean()
  def visible_paints?(node) do
    Enum.any?([node.fill_paints || [], node.stroke_paints || []], fn paints ->
      Enum.any?(paints, &(Map.get(&1, :visible) != false))
    end)
  end

  @spec draw_node(Skia.Document.t(), Node.t(), map()) :: Skia.Document.t()
  # Path text draws its stroke outlines first, under the glyphs they surround.
  def draw_node(document, %Node{node_type: :text_path} = node, assets),
    do:
      document
      |> draw_strokes(node, assets)
      |> draw_fills(node, assets)
      |> draw_emoji(node, assets)

  def draw_node(document, node, assets),
    do:
      document
      |> draw_fills(node, assets)
      |> draw_emoji(node, assets)
      |> draw_strokes(node, assets)

  # Emoji are drawn once, apart from the fills that paint the other glyphs.
  defp draw_emoji(document, node, %{text_emoji: emoji}) when is_map_key(emoji, node.guid) do
    Enum.reduce(emoji[node.guid], document, fn {text, opts}, drawn ->
      Skia.text(drawn, text, opts)
    end)
  end

  defp draw_emoji(document, _node, _assets), do: document

  # A vector whose paths have fills of their own draws each path in them, and the rest in its
  # own fills.
  defp draw_fills(document, %Node{node_type: :vector} = node, assets) do
    paths = geometry_paths(assets, node, :fill)

    if Enum.any?(paths, & &1.fills),
      do: Enum.reduce(paths, document, &draw_path_fills(&2, node, &1, assets)),
      else: Enum.reduce(node.fill_paints || [], document, &draw_fill(&2, node, &1, assets))
  end

  defp draw_fills(document, node, assets),
    do: Enum.reduce(node.fill_paints || [], document, &draw_fill(&2, node, &1, assets))

  defp draw_path_fills(document, node, geometry, assets) do
    Enum.reduce(geometry.fills || node.fill_paints || [], document, fn paint, drawn ->
      draw_path_fill(drawn, node, geometry, paint, assets)
    end)
  end

  defp draw_path_fill(document, node, geometry, paint, assets) do
    case Paint.resolve(paint, node.size, assets.images) do
      {:ok, resolved} ->
        path_opts = [fill: resolved.paint, fill_rule: geometry.fill_rule]
        draw = &Skia.path(&1, geometry.path, path_opts)

        if is_number(resolved.opacity) and resolved.opacity < 1,
          do: Skia.layer(document, [opacity: resolved.opacity], draw),
          else: draw.(document)

      {:error, _reason} ->
        document
    end
  end

  defp draw_strokes(document, node, assets) do
    stroke = node.stroke || %Stroke{}
    Enum.reduce(node.stroke_paints || [], document, &draw_stroke(&2, node, &1, stroke, assets))
  end

  @doc false
  @spec stroke_alignment_supported?(Node.t() | map()) :: boolean()
  def stroke_alignment_supported?(%{node_type: type}) when type in [:vector, :boolean_operation],
    do: false

  def stroke_alignment_supported?(%{node_type: type}), do: type in @stroke_alignment_types

  @doc false
  @spec stroke_alignment_supported?(Node.t(), map()) :: boolean()
  def stroke_alignment_supported?(%Node{node_type: type} = node, assets)
      when type in [:vector, :boolean_operation],
      do: baked_stroke?(node, assets) or alignment_silhouette_paths(assets, node) != []

  def stroke_alignment_supported?(node, _assets), do: stroke_alignment_supported?(node)

  @doc false
  @spec effect_shape_supported?(Node.t() | map()) :: boolean()
  def effect_shape_supported?(%{node_type: type}), do: type in @effect_shape_types

  @doc false
  @spec clip_children(Skia.Document.t(), Node.t()) :: Skia.Document.t()
  def clip_children(
        document,
        %Node{size: %{x: width, y: height}} = node
      ) do
    corners = node_corners(node)

    cond do
      not CornerRadii.valid?(corners) ->
        document

      corners.independent? ->
        Skia.clip_path(document, independent_corner_path({0.0, 0.0, width, height}, corners))

      true ->
        Skia.clip_rect(document,
          x: 0,
          y: 0,
          width: width,
          height: height,
          radius: corners.top_left
        )
    end
  end

  def clip_children(document, _node), do: document

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
    draw_rect(
      document,
      node,
      width,
      height,
      [
        fill: Keyword.get(opts, :fill, :white),
        blend_mode: Keyword.get(opts, :blend_mode, :src_over)
      ],
      Keyword.get(effect_opts, :inset, 0.0)
    )
  end

  def draw_silhouette(
        document,
        %Node{node_type: :ellipse, shape: %Arc{}} = node,
        _assets,
        opts,
        effect_opts
      ) do
    draw_primitive_silhouette(document, node, opts, effect_opts)
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
        _assets,
        opts,
        effect_opts
      )
      when type in @primitive_path_types do
    draw_primitive_silhouette(document, node, opts, effect_opts)
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

  def draw_silhouette(document, %Node{node_type: type} = node, assets, opts, _effect_opts)
      when type in @text_types and is_map_key(assets.text_glyphs, node.guid) do
    path_opts = [
      fill: Keyword.get(opts, :fill, :white),
      blend_mode: Keyword.get(opts, :blend_mode, :src_over)
    ]

    draw_saved_text(document, node, assets, path_opts, false)
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

  defp draw_primitive_silhouette(document, node, opts, effect_opts) do
    case primitive_path(node, Keyword.get(effect_opts, :inset, 0.0)) do
      %{__struct__: Skia.Path} = path ->
        path_opts = [
          fill: Keyword.get(opts, :fill, :white),
          blend_mode: Keyword.get(opts, :blend_mode, :src_over)
        ]

        Skia.path(document, path, path_opts)

      nil ->
        document
    end
  end

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

  # Figma saves a vector's stroke as an outline already offset for its alignment, which is
  # painted like a fill; only a centred stroke of an unfilled vector follows its network.
  defp draw_resolved_stroke(
         document,
         %Node{node_type: type} = node,
         opts,
         resolved,
         assets,
         stroke
       )
       when type in [:vector, :boolean_operation] and is_map_key(assets.geometries, node.guid) do
    case Map.get(assets.geometries[node.guid], :stroke, []) do
      [_ | _] = outlines ->
        if network_centerline?(node, stroke),
          do: draw_resolved(document, node, :stroke, opts, resolved, assets),
          else: draw_stroke_outlines(document, node, outlines, opts, resolved, assets, stroke)

      [] ->
        draw_unbaked_stroke(document, node, opts, resolved, assets, stroke)
    end
  end

  defp draw_resolved_stroke(document, node, opts, resolved, assets, stroke),
    do: draw_unbaked_stroke(document, node, opts, resolved, assets, stroke)

  # A saved stroke outline is already offset for its alignment.
  defp baked_stroke?(node, assets),
    do: match?(%{stroke: [_ | _]}, Map.get(assets.geometries, node.guid))

  defp network_centerline?(node, stroke) do
    stroke.align in [nil, :center] and node.corner_radius in [nil, 0, 0.0] and
      not is_nil(node.vector_network) and
      not Enum.any?(node.fill_paints || [], &(&1.visible != false))
  end

  defp draw_stroke_outlines(document, node, outlines, opts, resolved, assets, stroke) do
    paint_opts = [fill: Keyword.fetch!(opts, :stroke)]

    draw = fn canvas ->
      Enum.reduce(outlines, canvas, fn geometry, drawn ->
        Skia.path(drawn, geometry.path, Keyword.put(paint_opts, :fill_rule, geometry.fill_rule))
      end)
    end

    draw =
      if stroke.align == :inside,
        do: fn canvas -> Skia.group(canvas, [], &draw.(clip_to_fill(&1, node, assets))) end,
        else: draw

    if is_number(resolved.opacity) and resolved.opacity < 1,
      do: Skia.layer(document, [opacity: resolved.opacity], draw),
      else: draw.(document)
  end

  defp clip_to_fill(document, node, assets) do
    assets
    |> geometry_paths(node, :fill)
    |> Enum.reduce(document, &Skia.clip_path(&2, &1.path))
  end

  defp draw_unbaked_stroke(document, node, opts, resolved, assets, stroke)
       when stroke.align in [:inside, :outside] do
    if stroke_alignment_supported?(node, assets) do
      draw_aligned_stroke(document, node, opts, resolved, assets, stroke)
    else
      draw_resolved(document, node, :stroke, opts, resolved, assets)
    end
  end

  defp draw_unbaked_stroke(document, node, opts, resolved, assets, _stroke),
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
      draw_alignment_silhouette(mask, node, assets)
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
         %Node{node_type: :ellipse, shape: %Arc{}} = node,
         _kind,
         opts,
         _assets
       ),
       do: draw_primitive_path(document, node, opts)

  defp draw_shape(
         document,
         %Node{node_type: :ellipse, size: size},
         _kind,
         opts,
         _assets
       ),
       do: Skia.oval(document, Keyword.merge([x: 0, y: 0, width: size.x, height: size.y], opts))

  defp draw_shape(
         document,
         %Node{node_type: type} = node,
         _kind,
         opts,
         _assets
       )
       when type in @primitive_path_types,
       do: draw_primitive_path(document, node, opts)

  defp draw_shape(document, %Node{node_type: :line, size: size}, _kind, opts, _assets) do
    line_opts =
      Keyword.merge(
        [from: {0, 0}, to: {size.x, size.y}],
        line_paint_opts(opts)
      )

    Skia.line(document, line_opts)
  end

  defp draw_shape(document, %Node{node_type: type} = node, :fill, opts, assets)
       when type in @text_types and is_map_key(assets.text_glyphs, node.guid),
       do: draw_saved_text(document, node, assets, [fill: Keyword.fetch!(opts, :fill)], true)

  # Path text keeps its stroke as saved outline geometry, painted like a fill. Its vector data
  # is the path it follows, not an outline to paint.
  defp draw_shape(document, %Node{node_type: :text_path} = node, :stroke, opts, assets) do
    assets.geometries
    |> Map.get(node.guid, %{})
    |> Map.get(:stroke, [])
    |> Enum.reduce(document, fn geometry, rendered ->
      Skia.path(rendered, geometry.path,
        fill: Keyword.fetch!(opts, :stroke),
        fill_rule: geometry.fill_rule
      )
    end)
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
       when type in @rectangular_types,
       do: draw_rect(document, node, width, height, opts, 0.0)

  defp draw_shape(document, _node, _kind, _opts, _assets), do: document

  defp draw_rect(document, node, width, height, opts, inset) do
    source_corners = node_corners(node)
    corners = CornerRadii.inset(source_corners, inset)
    rect = {inset, inset, max(width - inset * 2, 0.0), max(height - inset * 2, 0.0)}

    cond do
      not CornerRadii.valid?(source_corners) ->
        document

      corners.independent? ->
        Skia.path(document, independent_corner_path(rect, corners), opts)

      true ->
        {x, y, rect_width, rect_height} = rect

        Skia.rect(
          document,
          Keyword.merge(
            [x: x, y: y, width: rect_width, height: rect_height, radius: corners.top_left],
            opts
          )
        )
    end
  end

  defp node_corners(%Node{corners: %CornerRadii{} = corners}), do: corners

  defp node_corners(%Node{corner_radius: radius}),
    do: CornerRadii.from_source(%{corner_radius: radius})

  defp independent_corner_path({x, y, width, height}, corners) do
    %{top_left: tl, top_right: tr, bottom_right: br, bottom_left: bl} =
      normalize_corner_radii(corners, width, height)

    right = x + width
    bottom = y + height

    Skia.Path.new()
    |> Skia.Path.move_to(x + tl, y)
    |> Skia.Path.line_to(right - tr, y)
    |> top_right_corner(right, y, tr)
    |> Skia.Path.line_to(right, bottom - br)
    |> bottom_right_corner(right, bottom, br)
    |> Skia.Path.line_to(x + bl, bottom)
    |> bottom_left_corner(x, bottom, bl)
    |> Skia.Path.line_to(x, y + tl)
    |> top_left_corner(x, y, tl)
    |> Skia.Path.close()
  end

  defp normalize_corner_radii(corners, width, height) do
    scale =
      [
        radius_scale(width, corners.top_left + corners.top_right),
        radius_scale(width, corners.bottom_left + corners.bottom_right),
        radius_scale(height, corners.top_left + corners.bottom_left),
        radius_scale(height, corners.top_right + corners.bottom_right)
      ]
      |> Enum.min()

    %{
      top_left: corners.top_left * scale,
      top_right: corners.top_right * scale,
      bottom_right: corners.bottom_right * scale,
      bottom_left: corners.bottom_left * scale
    }
  end

  defp radius_scale(_side, sum) when sum <= 0, do: 1.0
  defp radius_scale(side, sum), do: min(1.0, max(side, 0.0) / sum)

  defp top_right_corner(path, right, top, radius) when radius <= 0,
    do: Skia.Path.line_to(path, right, top)

  defp top_right_corner(path, _right, _top, radius),
    do: Skia.Path.r_arc_to(path, {radius, radius}, 0, false, :cw, {radius, radius})

  defp bottom_right_corner(path, right, bottom, radius) when radius <= 0,
    do: Skia.Path.line_to(path, right, bottom)

  defp bottom_right_corner(path, _right, _bottom, radius),
    do: Skia.Path.r_arc_to(path, {radius, radius}, 0, false, :cw, {-radius, radius})

  defp bottom_left_corner(path, left, bottom, radius) when radius <= 0,
    do: Skia.Path.line_to(path, left, bottom)

  defp bottom_left_corner(path, _left, _bottom, radius),
    do: Skia.Path.r_arc_to(path, {radius, radius}, 0, false, :cw, {-radius, -radius})

  defp top_left_corner(path, left, top, radius) when radius <= 0,
    do: Skia.Path.line_to(path, left, top)

  defp top_left_corner(path, _left, _top, radius),
    do: Skia.Path.r_arc_to(path, {radius, radius}, 0, false, :cw, {radius, -radius})

  defp draw_primitive_path(document, node, opts) do
    case primitive_path(node, 0.0) do
      %{__struct__: Skia.Path} = path -> Skia.path(document, path, opts)
      nil -> document
    end
  end

  defp primitive_path(%Node{shape: shape, size: size}, inset)
       when is_map(size) and is_number(inset) do
    if PrimitiveShape.valid?(shape) do
      shape_path(shape, size, inset)
    end
  end

  defp primitive_path(_node, _inset), do: nil

  defp shape_path(%Polygon{point_count: count}, size, inset),
    do: polygon_path(size, inset, count, 1.0)

  defp shape_path(%Star{point_count: count, inner_scale: scale}, size, inset),
    do: polygon_path(size, inset, count * 2, scale)

  defp shape_path(%Arc{} = arc, size, inset), do: arc_path(size, inset, arc)

  defp polygon_path(size, inset, total_points, inner_scale) do
    {x, y, width, height} = inset_rect(size, inset)
    center_x = x + width / 2
    center_y = y + height / 2
    radius_x = width / 2
    radius_y = height / 2

    0..(total_points - 1)
    |> Enum.reduce(Skia.Path.new(), fn index, path ->
      angle = -:math.pi() / 2 + 2 * :math.pi() * index / total_points
      radius = if total_points > 0 and rem(index, 2) == 1, do: inner_scale, else: 1.0
      point_x = center_x + radius_x * radius * :math.cos(angle)
      point_y = center_y + radius_y * radius * :math.sin(angle)

      if index == 0,
        do: Skia.Path.move_to(path, point_x, point_y),
        else: Skia.Path.line_to(path, point_x, point_y)
    end)
    |> Skia.Path.close()
  end

  defp arc_path(size, inset, arc) do
    {x, y, width, height} = inset_rect(size, inset)
    start_degrees = radians_to_degrees(arc.start_angle)
    sweep_degrees = radians_to_degrees(arc.end_angle - arc.start_angle)
    center_x = x + width / 2
    center_y = y + height / 2
    outer_start = ellipse_point(center_x, center_y, width / 2, height / 2, arc.start_angle)

    cond do
      arc.inner_radius > 0 ->
        inner_width = width * arc.inner_radius
        inner_height = height * arc.inner_radius
        inner_x = center_x - inner_width / 2
        inner_y = center_y - inner_height / 2

        inner_end =
          ellipse_point(
            center_x,
            center_y,
            inner_width / 2,
            inner_height / 2,
            arc.end_angle
          )

        Skia.Path.new()
        |> Skia.Path.move_to(elem(outer_start, 0), elem(outer_start, 1))
        |> append_ellipse_arc({x, y, width, height}, start_degrees, sweep_degrees)
        |> Skia.Path.line_to(elem(inner_end, 0), elem(inner_end, 1))
        |> append_ellipse_arc(
          {inner_x, inner_y, inner_width, inner_height},
          start_degrees + sweep_degrees,
          -sweep_degrees
        )
        |> Skia.Path.close()

      abs(sweep_degrees) >= 359.99 ->
        Skia.Path.new()
        |> Skia.Path.move_to(elem(outer_start, 0), elem(outer_start, 1))
        |> append_ellipse_arc({x, y, width, height}, start_degrees, sweep_degrees)
        |> Skia.Path.close()

      true ->
        Skia.Path.new()
        |> Skia.Path.move_to(center_x, center_y)
        |> Skia.Path.line_to(elem(outer_start, 0), elem(outer_start, 1))
        |> append_ellipse_arc({x, y, width, height}, start_degrees, sweep_degrees)
        |> Skia.Path.close()
    end
  end

  defp append_ellipse_arc(path, rect, start_degrees, sweep_degrees)
       when abs(sweep_degrees) >= 359.99 do
    half_sweep = sweep_degrees / 2

    path
    |> Skia.Path.arc_to(rect, start_degrees, half_sweep)
    |> Skia.Path.arc_to(rect, start_degrees + half_sweep, half_sweep)
  end

  defp append_ellipse_arc(path, rect, start_degrees, sweep_degrees),
    do: Skia.Path.arc_to(path, rect, start_degrees, sweep_degrees)

  defp inset_rect(size, inset) do
    {inset, inset, max(size.x - inset * 2, 0.0), max(size.y - inset * 2, 0.0)}
  end

  defp ellipse_point(center_x, center_y, radius_x, radius_y, angle) do
    {center_x + radius_x * :math.cos(angle), center_y + radius_y * :math.sin(angle)}
  end

  defp radians_to_degrees(value), do: value * 180 / :math.pi()

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

  # Saved glyph outlines, each run of them in its style run's colours when it has its own.
  defp draw_saved_text(document, node, assets, path_opts, run_fills?) do
    document =
      Enum.reduce(assets.text_glyphs[node.guid], document, fn {run, path}, drawn ->
        node
        |> glyph_fills(run, assets, path_opts, run_fills?)
        |> Enum.reduce(drawn, &Skia.path(&2, path, Keyword.put(path_opts, :fill, &1)))
      end)

    node.text
    |> Glyphs.decorations()
    |> Enum.reduce(document, &draw_decoration(&2, &1, node, assets, path_opts, run_fills?))
  end

  defp glyph_fills(node, run, assets, _path_opts, true) when not is_nil(run),
    do: run.fill_paints |> Enum.map(&solid_fill(&1, node, assets)) |> Enum.reject(&is_nil/1)

  defp glyph_fills(_node, _run, _assets, path_opts, _run_fills?),
    do: [Keyword.fetch!(path_opts, :fill)]

  defp solid_fill(%{visible: false}, _node, _assets), do: nil

  defp solid_fill(%{type: :solid} = paint, node, assets) do
    {:ok, resolved} = Paint.resolve(paint, node.size, assets.images)
    resolved.paint
  end

  defp solid_fill(_paint, _node, _assets), do: nil

  defp draw_decoration(document, decoration, node, assets, path_opts, run_fills?) do
    own =
      if run_fills?,
        do: Enum.find_value(decoration.fill_paints, &solid_fill(&1, node, assets))

    opts = if own, do: Keyword.put(path_opts, :fill, own), else: path_opts
    draw_decoration_rect(document, decoration.style, decoration.rect, opts)
  end

  # Dots one thickness wide, two apart, as Figma draws a dotted underline.
  defp draw_decoration_rect(document, :dotted, {x, y, width, height}, opts) when height > 0 do
    count = floor((width - height) / (height * 2)) + 1

    Enum.reduce(0..(count - 1)//1, document, fn index, drawn ->
      oval = [x: x + index * height * 2, y: y, width: height, height: height]
      Skia.oval(drawn, Keyword.merge(oval, opts))
    end)
  end

  # A cosine through the rect's middle, starting in a trough.
  defp draw_decoration_rect(document, :wavy, {x, y, width, height}, opts) do
    amplitude = height / 2
    period = height * 3.5
    middle = y + amplitude
    step = max(0.25, period / 32)
    wave_y = fn at -> middle + amplitude * :math.cos((at - x) / period * :math.pi() * 2) end

    path =
      Stream.iterate(x + step, &(&1 + step))
      |> Enum.take_while(&(&1 < x + width))
      |> Enum.concat([x + width])
      |> Enum.reduce(Skia.Path.move_to(Skia.Path.new(), x, middle + amplitude), fn at, wave ->
        Skia.Path.line_to(wave, at, wave_y.(at))
      end)

    {fill, opts} = Keyword.pop!(opts, :fill)
    Skia.path(document, path, Keyword.merge(opts, stroke: fill, stroke_width: height * 2 / 3))
  end

  defp draw_decoration_rect(document, _style, {x, y, width, height}, opts),
    do: Skia.rect(document, Keyword.merge([x: x, y: y, width: width, height: height], opts))

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

  defp draw_alignment_silhouette(document, %Node{node_type: type} = node, assets)
       when type in [:vector, :boolean_operation] do
    Enum.reduce(alignment_silhouette_paths(assets, node), document, fn geometry, rendered ->
      Skia.path(rendered, geometry.path, fill: :white, fill_rule: geometry.fill_rule)
    end)
  end

  defp draw_alignment_silhouette(document, node, assets),
    do: draw_silhouette(document, node, assets, fill: :white)

  defp alignment_silhouette_paths(assets, node) do
    fill_paths = geometry_paths(assets, node, :fill)
    stroke_paths = geometry_paths(assets, node, :stroke)
    closed_strokes? = stroke_paths != [] and Enum.all?(stroke_paths, & &1.closed?)

    cond do
      closed_strokes? and fill_paths != [] and Enum.all?(fill_paths, & &1.closed?) -> fill_paths
      closed_strokes? -> stroke_paths
      true -> []
    end
  end

  defp geometry_paths(assets, %{vector_network: reference} = node, kind)
       when not is_nil(reference) and is_map_key(assets.vector_geometries, node.guid),
       do: Map.get(assets.vector_geometries[node.guid], kind, [])

  # Without a network or a saved stroke outline, a stroke follows the saved fill outline.
  defp geometry_paths(assets, node, :stroke) do
    case Map.get(assets.geometries, node.guid, %{}) do
      %{stroke: [_ | _] = outlines} -> outlines
      geometries -> Map.get(geometries, :fill, [])
    end
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
