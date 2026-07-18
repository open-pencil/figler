defmodule Figler.Render.Skia do
  @compile {:no_warn_undefined, [Skia, Skia.Document]}

  @moduledoc """
  Compiles a `Figler.Render.Scene` into one batched `%Skia.Document{}`.

  Figma decoding and effective graph semantics remain in Figler; drawing and
  raster encoding remain in Skia.
  """

  alias Figler.Render.Bounds
  alias Figler.Render.Scene, as: RenderScene
  alias Figler.Scene.Graph.GUID
  alias Figler.Scene.Node

  @identity {1.0, 0.0, 0.0, 0.0, 1.0, 0.0}
  @container_types ["canvas", "component", "frame", "instance", "symbol"]

  @type bounds :: Bounds.t()

  @doc "Compiles an effective scene into a Skia command document."
  @spec compile(RenderScene.t(), keyword()) ::
          {:ok,
           %{document: Skia.Document.t(), root: String.t(), bounds: bounds(), warnings: [map()]}}
          | {:error, term()}
  def compile(%RenderScene{} = scene, opts \\ []) do
    with {:ok, root_guid} <- select_root(scene, opts),
         {:ok, bounds} <- content_bounds(scene, root_guid) do
      compile_root(scene, root_guid, bounds, opts)
    end
  end

  defp compile_root(scene, root_guid, bounds, opts) do
    child_guids = render_guids(scene, root_guid)
    warnings = collect_warnings(scene, child_guids)

    if Keyword.get(opts, :strict, false) and warnings != [] do
      {:error, {:unsupported_render_features, warnings}}
    else
      document = build_document(scene, child_guids, bounds, opts)

      {:ok,
       %{
         document: document,
         root: GUID.format(root_guid),
         bounds: bounds,
         warnings: warnings
       }}
    end
  end

  defp build_document(scene, child_guids, bounds, opts) do
    scale = opts |> Keyword.get(:scale, 1.0) |> :erlang.float()
    width = max(1, ceil((bounds.max_x - bounds.min_x) * scale))
    height = max(1, ceil((bounds.max_y - bounds.min_y) * scale))

    width
    |> Skia.canvas(height)
    |> Skia.clear(Keyword.get(opts, :background, :transparent))
    |> Skia.group([scale: {scale, scale}], fn scaled ->
      render_scaled(scaled, scene, child_guids, bounds)
    end)
  end

  defp render_scaled(document, scene, child_guids, bounds) do
    Skia.group(document, [translate: {-bounds.min_x, -bounds.min_y}], fn translated ->
      render_nodes(translated, scene, child_guids)
    end)
  end

  defp select_root(scene, opts) do
    case Keyword.get(opts, :root, Keyword.get(opts, :page)) do
      nil -> canvas_at(scene, 0)
      index when is_integer(index) -> canvas_at(scene, index)
      value -> select_named_root(scene, value)
    end
  end

  defp canvas_at(scene, index) do
    scene
    |> canvas_guids()
    |> Enum.at(index)
    |> case do
      nil -> {:error, :render_root_not_found}
      guid -> {:ok, guid}
    end
  end

  defp select_named_root(scene, value) do
    parsed = GUID.parse(value)

    cond do
      parsed && Map.has_key?(scene.graph.nodes, parsed) ->
        {:ok, parsed}

      is_binary(value) ->
        scene
        |> canvas_guids()
        |> Enum.find(&(Map.get(scene.graph.nodes, &1).name == value))
        |> case do
          nil -> {:error, :render_root_not_found}
          guid -> {:ok, guid}
        end

      true ->
        {:error, :render_root_not_found}
    end
  end

  defp canvas_guids(scene) do
    Enum.flat_map(scene.message.node_changes, fn node ->
      guid = GUID.from_schema(node.guid)

      case Map.get(scene.graph.nodes, guid) do
        %Node{node_type: "canvas"} -> [guid]
        _node -> []
      end
    end)
  end

  defp content_bounds(scene, root_guid) do
    bounds =
      scene
      |> render_guids(root_guid)
      |> Enum.reduce(nil, &node_bounds(scene, &1, @identity, &2))

    if bounds, do: {:ok, bounds}, else: {:error, :empty_render_root}
  end

  defp render_guids(scene, root_guid) do
    case Map.get(scene.graph.nodes, root_guid) do
      %Node{node_type: "canvas"} -> Map.get(scene.graph.children, root_guid, [])
      %Node{} -> [root_guid]
      nil -> []
    end
  end

  defp node_bounds(scene, guid, parent_matrix, bounds) do
    case Map.get(scene.graph.nodes, guid) do
      %Node{visible: visible} = node when visible != false ->
        matrix = multiply(parent_matrix, matrix(node.transform))
        bounds = include_rect(bounds, matrix, node.size)

        scene.graph.children
        |> Map.get(guid, [])
        |> Enum.reduce(bounds, &node_bounds(scene, &1, matrix, &2))

      _missing_or_hidden ->
        bounds
    end
  end

  defp include_rect(bounds, _matrix, nil), do: bounds

  defp include_rect(bounds, matrix, %{x: width, y: height})
       when is_number(width) and is_number(height) do
    points = [
      point(matrix, 0, 0),
      point(matrix, width, 0),
      point(matrix, 0, height),
      point(matrix, width, height)
    ]

    [first | rest] = points

    point_bounds =
      Enum.reduce(rest, point_bounds(first), fn {x, y}, acc ->
        %Bounds{
          min_x: min(acc.min_x, x),
          min_y: min(acc.min_y, y),
          max_x: max(acc.max_x, x),
          max_y: max(acc.max_y, y)
        }
      end)

    union(bounds, point_bounds)
  end

  defp include_rect(bounds, _matrix, _size), do: bounds

  defp point_bounds({x, y}), do: %Bounds{min_x: x, min_y: y, max_x: x, max_y: y}

  defp union(nil, bounds), do: bounds

  defp union(left, right) do
    %Bounds{
      min_x: min(left.min_x, right.min_x),
      min_y: min(left.min_y, right.min_y),
      max_x: max(left.max_x, right.max_x),
      max_y: max(left.max_y, right.max_y)
    }
  end

  defp render_nodes(document, scene, guids) do
    Enum.reduce(guids, document, &render_node(scene, &1, &2))
  end

  defp render_node(scene, guid, document) do
    case Map.get(scene.graph.nodes, guid) do
      %Node{visible: visible} = node when visible != false ->
        source = source_node(scene, guid)

        Skia.group(document, [concat: matrix(node.transform)], fn transformed ->
          render_transformed(transformed, scene, guid, node, source)
        end)

      _missing_or_hidden ->
        document
    end
  end

  defp render_transformed(document, scene, guid, %Node{opacity: opacity} = node, source)
       when is_number(opacity) and opacity < 1 do
    Skia.layer(document, [opacity: opacity], fn layer ->
      render_node_content(layer, scene, guid, node, source)
    end)
  end

  defp render_transformed(document, scene, guid, node, source) do
    render_node_content(document, scene, guid, node, source)
  end

  defp render_node_content(document, scene, guid, node, source) do
    document
    |> draw_node(node, source)
    |> render_children(scene, node, source, guid)
  end

  defp render_children(document, scene, node, source, guid) do
    children = Map.get(scene.graph.children, guid, [])

    if children == [] do
      document
    else
      document
      |> maybe_clip(node, source)
      |> render_nodes(scene, children)
    end
  end

  defp maybe_clip(document, %Node{node_type: type, size: %{x: width, y: height}}, source)
       when type in @container_types do
    if source && source.frame_mask_disabled == false do
      Skia.clip_rect(document,
        x: 0,
        y: 0,
        width: width,
        height: height,
        radius: source.corner_radius || 0
      )
    else
      document
    end
  end

  defp maybe_clip(document, _node, _source), do: document

  defp draw_node(document, node, source) do
    paints = if source, do: source.fill_paints || [], else: []
    document = Enum.reduce(paints, document, &draw_fill(&2, node, source, &1))
    strokes = if source, do: source.stroke_paints || [], else: []
    weight = if source, do: source.stroke_weight || 1, else: 1
    Enum.reduce(strokes, document, &draw_stroke(&2, node, source, &1, weight))
  end

  defp draw_fill(document, _node, _source, %{visible: false}), do: document

  defp draw_fill(document, node, source, %{type: :solid} = paint),
    do: draw_shape(document, node, source, fill: color(paint))

  defp draw_fill(document, _node, _source, _paint), do: document

  defp draw_stroke(document, _node, _source, %{visible: false}, _weight), do: document

  defp draw_stroke(document, node, source, %{type: :solid} = paint, weight),
    do: draw_shape(document, node, source, stroke: color(paint), stroke_width: weight)

  defp draw_stroke(document, _node, _source, _paint, _weight), do: document

  defp draw_shape(document, %Node{node_type: "ellipse", size: size}, _source, opts),
    do: Skia.oval(document, Keyword.merge([x: 0, y: 0, width: size.x, height: size.y], opts))

  defp draw_shape(document, %Node{node_type: "line", size: size}, _source, opts) do
    Skia.line(document,
      from: {0, 0},
      to: {size.x, size.y},
      stroke: Keyword.get(opts, :stroke, Keyword.get(opts, :fill, :black)),
      stroke_width: Keyword.get(opts, :stroke_width, 1)
    )
  end

  defp draw_shape(
         document,
         %Node{node_type: "text", text: text, size: size} = node,
         _source,
         opts
       ) do
    text_opts = [
      x: 0,
      y: 0,
      size: node.font_size || 14,
      font_family: node.font_family || "Arial",
      fill: Keyword.get(opts, :fill, Keyword.get(opts, :stroke, :black))
    ]

    text_opts = if size, do: Keyword.put(text_opts, :width, size.x), else: text_opts
    Skia.text(document, text || "", text_opts)
  end

  defp draw_shape(document, %Node{size: %{x: width, y: height}}, source, opts) do
    Skia.rect(
      document,
      Keyword.merge(
        [x: 0, y: 0, width: width, height: height, radius: (source && source.corner_radius) || 0],
        opts
      )
    )
  end

  defp draw_shape(document, _node, _source, _opts), do: document

  defp collect_warnings(scene, guids) do
    guids
    |> Enum.reduce([], &node_warnings(scene, &1, &2))
    |> Enum.reverse()
    |> Enum.uniq()
  end

  defp node_warnings(scene, guid, warnings) do
    case Map.get(scene.graph.nodes, guid) do
      %Node{visible: visible} when visible != false ->
        source = source_node(scene, guid)
        warnings = prepend_source_warnings(warnings, source, guid)

        scene.graph.children
        |> Map.get(guid, [])
        |> Enum.reduce(warnings, &node_warnings(scene, &1, &2))

      _missing_or_hidden ->
        warnings
    end
  end

  defp prepend_source_warnings(warnings, nil, _guid), do: warnings

  defp prepend_source_warnings(warnings, source, guid) do
    source_warnings =
      unsupported_paints(guid, :fill, source.fill_paints || []) ++
        unsupported_paints(guid, :stroke, source.stroke_paints || [])

    Enum.reduce(source_warnings, warnings, &[&1 | &2])
  end

  defp unsupported_paints(guid, kind, paints) do
    Enum.flat_map(paints, fn
      %{visible: false} -> []
      %{type: :solid} -> []
      paint -> [%{guid: GUID.format(guid), feature: kind, value: paint.type}]
    end)
  end

  defp source_node(scene, guid) do
    source_guid =
      scene.graph.provenance
      |> Map.get(guid, %{})
      |> Map.get(:source_guid, guid)

    Map.get(scene.source_nodes, source_guid)
  end

  defp color(paint) do
    value = paint.color || %{}
    opacity = (paint.opacity || 1.0) * (Map.get(value, :a) || 1.0)

    {:rgba, channel(Map.get(value, :r)), channel(Map.get(value, :g)), channel(Map.get(value, :b)),
     channel(opacity)}
  end

  defp channel(nil), do: 0
  defp channel(value), do: value |> Kernel.*(255) |> round() |> max(0) |> min(255)

  defp matrix(nil), do: @identity

  defp matrix(value) do
    {value.m00 || 1.0, value.m01 || 0.0, value.m02 || 0.0, value.m10 || 0.0, value.m11 || 1.0,
     value.m12 || 0.0}
  end

  defp multiply({a, b, c, d, e, f}, {g, h, i, j, k, l}) do
    {a * g + b * j, a * h + b * k, a * i + b * l + c, d * g + e * j, d * h + e * k,
     d * i + e * l + f}
  end

  defp point({a, b, c, d, e, f}, x, y), do: {a * x + b * y + c, d * x + e * y + f}
end
