defmodule Figler.Render.Skia do
  @compile {:no_warn_undefined, [Skia, Skia.Document, Skia.Image]}

  @moduledoc """
  Compiles a `Figler.Render.Scene` into one batched `%Skia.Document{}`.

  Figma decoding and effective graph semantics remain in Figler; drawing and
  raster encoding remain in Skia.
  """

  alias Figler.Render.Affine
  alias Figler.Render.Bounds
  alias Figler.Render.Geometry
  alias Figler.Render.Scene, as: RenderScene
  alias Figler.Render.Skia.Paint
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
  def compile(%RenderScene{root: root_guid} = scene, opts \\ []) do
    with {:ok, bounds} <- content_bounds(scene, root_guid) do
      compile_root(scene, root_guid, bounds, opts)
    end
  end

  defp compile_root(scene, root_guid, bounds, opts) do
    child_guids = render_guids(scene, root_guid)
    assets = load_render_assets(scene)
    warnings = collect_warnings(scene, child_guids, assets)

    if Keyword.get(opts, :strict, false) and warnings != [] do
      {:error, {:unsupported_render_features, warnings}}
    else
      document = build_document(scene, child_guids, bounds, assets, opts)

      {:ok,
       %{
         document: document,
         root: GUID.format(root_guid),
         bounds: bounds,
         warnings: warnings
       }}
    end
  end

  defp build_document(scene, child_guids, bounds, assets, opts) do
    scale = opts |> Keyword.get(:scale, 1.0) |> :erlang.float()
    width = max(1, ceil((bounds.max_x - bounds.min_x) * scale))
    height = max(1, ceil((bounds.max_y - bounds.min_y) * scale))

    width
    |> Skia.canvas(height)
    |> Skia.clear(Keyword.get(opts, :background, :transparent))
    |> Skia.group([scale: {scale, scale}], fn scaled ->
      render_scaled(scaled, scene, child_guids, bounds, assets)
    end)
  end

  defp render_scaled(document, scene, child_guids, bounds, assets) do
    Skia.group(document, [translate: {-bounds.min_x, -bounds.min_y}], fn translated ->
      render_nodes(translated, scene, child_guids, assets)
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
      %Node{visible: visible, node_type: "boolean_operation"} = node when visible != false ->
        matrix = Affine.multiply(parent_matrix, matrix(node.transform))
        include_rect(bounds, matrix, node.size)

      %Node{visible: visible} = node when visible != false ->
        matrix = Affine.multiply(parent_matrix, matrix(node.transform))
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

  defp render_nodes(document, scene, guids, assets) do
    Enum.reduce(guids, document, &render_node(scene, assets, &1, &2))
  end

  defp render_node(scene, assets, guid, document) do
    case Map.get(scene.graph.nodes, guid) do
      %Node{visible: visible} = node when visible != false ->
        source = source_node(scene, guid)

        Skia.group(document, [concat: matrix(node.transform)], fn transformed ->
          render_transformed(transformed, scene, guid, node, source, assets)
        end)

      _missing_or_hidden ->
        document
    end
  end

  defp render_transformed(document, scene, guid, %Node{opacity: opacity} = node, source, assets)
       when is_number(opacity) and opacity < 1 do
    Skia.layer(document, [opacity: opacity], fn layer ->
      render_node_content(layer, scene, guid, node, source, assets)
    end)
  end

  defp render_transformed(document, scene, guid, node, source, assets) do
    render_node_content(document, scene, guid, node, source, assets)
  end

  defp render_node_content(document, scene, guid, node, source, assets) do
    document
    |> draw_node(node, source, assets)
    |> render_children(scene, node, source, guid, assets)
  end

  defp render_children(
         document,
         _scene,
         %Node{node_type: "boolean_operation"},
         _source,
         _guid,
         _assets
       ),
       do: document

  defp render_children(document, scene, node, source, guid, assets) do
    children = Map.get(scene.graph.children, guid, [])

    if children == [] do
      document
    else
      document
      |> maybe_clip(node, source)
      |> render_nodes(scene, children, assets)
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

  defp draw_node(document, node, source, assets) do
    paints = if source, do: source.fill_paints || [], else: []
    document = Enum.reduce(paints, document, &draw_fill(&2, node, source, &1, assets))
    strokes = if source, do: source.stroke_paints || [], else: []
    weight = if source, do: source.stroke_weight || 1, else: 1
    Enum.reduce(strokes, document, &draw_stroke(&2, node, source, &1, weight, assets))
  end

  defp draw_fill(document, node, source, paint, assets) do
    case Paint.resolve(paint, node.size, assets.images) do
      {:ok, resolved} ->
        draw_resolved(document, node, source, :fill, [fill: resolved.paint], resolved, assets)

      {:error, _reason} ->
        document
    end
  end

  defp draw_stroke(
         document,
         %Node{node_type: node_type},
         _source,
         %{type: paint_type},
         _weight,
         _assets
       )
       when node_type not in ["vector", "boolean_operation"] and paint_type != :solid,
       do: document

  defp draw_stroke(document, node, source, paint, weight, assets) do
    case Paint.resolve(paint, node.size, assets.images) do
      {:ok, resolved} ->
        opts = [stroke: resolved.paint, stroke_width: weight]
        draw_resolved(document, node, source, :stroke, opts, resolved, assets)

      {:error, _reason} ->
        document
    end
  end

  defp draw_resolved(document, node, source, kind, opts, %{opacity: opacity}, assets)
       when is_number(opacity) and opacity < 1 do
    Skia.layer(document, [opacity: opacity], &draw_shape(&1, node, source, kind, opts, assets))
  end

  defp draw_resolved(document, node, source, kind, opts, _resolved, assets),
    do: draw_shape(document, node, source, kind, opts, assets)

  defp draw_shape(
         document,
         %Node{node_type: type},
         source,
         kind,
         opts,
         assets
       )
       when type in ["vector", "boolean_operation"] do
    paths = geometry_paths(assets, source, kind)
    path_opts = geometry_paint_opts(opts, kind)

    Enum.reduce(paths, document, fn geometry, rendered ->
      Skia.path(rendered, geometry.path, Keyword.put(path_opts, :fill_rule, geometry.fill_rule))
    end)
  end

  defp draw_shape(
         document,
         %Node{node_type: "ellipse", size: size},
         _source,
         _kind,
         opts,
         _assets
       ),
       do: Skia.oval(document, Keyword.merge([x: 0, y: 0, width: size.x, height: size.y], opts))

  defp draw_shape(document, %Node{node_type: "line", size: size}, _source, _kind, opts, _assets) do
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
         _kind,
         opts,
         _assets
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

  defp draw_shape(document, %Node{size: %{x: width, y: height}}, source, _kind, opts, _assets) do
    Skia.rect(
      document,
      Keyword.merge(
        [x: 0, y: 0, width: width, height: height, radius: (source && source.corner_radius) || 0],
        opts
      )
    )
  end

  defp draw_shape(document, _node, _source, _kind, _opts, _assets), do: document

  defp geometry_paths(_assets, nil, _kind), do: []

  defp geometry_paths(assets, source, kind) do
    assets.geometries
    |> Map.get(source.guid, %{})
    |> Map.get(kind, [])
  end

  defp geometry_paint_opts(opts, :fill), do: opts

  defp geometry_paint_opts(opts, :stroke) do
    [fill: Keyword.get(opts, :stroke, :black)]
  end

  defp load_render_assets(scene) do
    scene
    |> load_image_assets()
    |> load_geometry_assets(scene)
  end

  defp load_image_assets(scene) do
    scene.source_nodes
    |> Map.values()
    |> Enum.flat_map(&source_image_keys/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.reduce(
      %{images: %{}, errors: %{}, geometries: %{}, geometry_errors: %{}},
      &load_image_asset(scene, &1, &2)
    )
  end

  defp source_image_keys(source) do
    [source.fill_paints || [], source.stroke_paints || []]
    |> Enum.flat_map(&Enum.map(&1, fn paint -> Paint.image_key(paint) end))
  end

  defp load_image_asset(scene, key, assets) do
    with data when is_binary(data) <- find_image_asset(scene.document, key),
         {:ok, image} <- Skia.Image.decode(data) do
      put_in(assets, [:images, key], image)
    else
      nil -> put_in(assets, [:errors, key], :missing_image_asset)
      {:error, reason} -> put_in(assets, [:errors, key], {:invalid_image_asset, reason})
    end
  end

  defp find_image_asset(document, {:blob, index}), do: Enum.at(document.blobs, index)

  defp find_image_asset(document, hash) do
    Map.get(document.images, hash) ||
      Enum.find_value(document.images, fn {path, data} ->
        if path |> Path.basename() |> Path.rootname() |> String.downcase() == hash, do: data
      end)
  end

  defp load_geometry_assets(assets, scene) do
    Enum.reduce(scene.source_nodes, assets, fn {_guid, source}, loaded ->
      loaded
      |> load_geometry_kind(source, :fill, source.fill_geometry || [], scene.document.blobs)
      |> load_geometry_kind(source, :stroke, source.stroke_geometry || [], scene.document.blobs)
    end)
  end

  defp load_geometry_kind(assets, _source, _kind, [], _blobs), do: assets

  defp load_geometry_kind(assets, source, kind, references, blobs) do
    case Geometry.paths(references, blobs) do
      {:ok, paths} -> put_geometry_result(assets, :geometries, source.guid, kind, paths)
      {:error, reason} -> put_geometry_result(assets, :geometry_errors, source.guid, kind, reason)
    end
  end

  defp put_geometry_result(assets, collection, guid, kind, value) do
    source_values = assets |> Map.fetch!(collection) |> Map.get(guid, %{}) |> Map.put(kind, value)
    put_in(assets, [collection, guid], source_values)
  end

  defp collect_warnings(scene, guids, assets) do
    guids
    |> Enum.reduce([], &node_warnings(scene, assets, &1, &2))
    |> Enum.reverse()
    |> Enum.uniq()
  end

  defp node_warnings(scene, assets, guid, warnings) do
    case Map.get(scene.graph.nodes, guid) do
      %Node{visible: visible} = node when visible != false ->
        source = source_node(scene, guid)
        warnings = prepend_source_warnings(warnings, source, node, guid, assets)

        scene.graph.children
        |> Map.get(guid, [])
        |> Enum.reduce(warnings, &node_warnings(scene, assets, &1, &2))

      _missing_or_hidden ->
        warnings
    end
  end

  defp prepend_source_warnings(warnings, nil, _node, _guid, _assets), do: warnings

  defp prepend_source_warnings(warnings, source, node, guid, assets) do
    source_warnings =
      paint_warnings(guid, :fill, source.fill_paints || [], node, assets) ++
        paint_warnings(guid, :stroke, source.stroke_paints || [], node, assets) ++
        geometry_warnings(guid, node, source, assets)

    Enum.reduce(source_warnings, warnings, &[&1 | &2])
  end

  defp paint_warnings(guid, kind, paints, node, assets) do
    Enum.flat_map(paints, &paint_warning(&1, guid, kind, node, assets))
  end

  defp paint_warning(%{visible: false}, _guid, _kind, _node, _assets), do: []

  defp paint_warning(
         %{type: paint_type},
         guid,
         :stroke,
         %Node{node_type: node_type},
         _assets
       )
       when node_type not in ["vector", "boolean_operation"] and paint_type != :solid,
       do: [warning(guid, :stroke, {paint_type, :non_solid_stroke_unsupported})]

  defp paint_warning(paint, guid, kind, node, assets) do
    case Paint.resolve(paint, node.size, assets.images) do
      {:ok, resolved} ->
        Enum.map(resolved.warnings, &warning(guid, kind, &1))

      {:error, :missing_image_asset} ->
        reason = Map.get(assets.errors, Paint.image_key(paint), :missing_image_asset)
        [warning(guid, kind, reason)]

      {:error, reason} ->
        [warning(guid, kind, {Map.get(paint, :type), reason})]
    end
  end

  defp geometry_warnings(guid, %Node{node_type: type}, source, assets)
       when type in ["vector", "boolean_operation"] do
    []
    |> geometry_warning(guid, source, assets, :fill, source.fill_paints || [])
    |> geometry_warning(guid, source, assets, :stroke, source.stroke_paints || [])
  end

  defp geometry_warnings(_guid, _node, _source, _assets), do: []

  defp geometry_warning(warnings, guid, source, assets, kind, paints) do
    if Enum.any?(paints, &(Map.get(&1, :visible) != false)) do
      case get_in(assets, [:geometry_errors, source.guid, kind]) do
        nil -> missing_geometry_warning(warnings, guid, source, kind)
        reason -> [warning(guid, kind, {:invalid_geometry, reason}) | warnings]
      end
    else
      warnings
    end
  end

  defp missing_geometry_warning(warnings, guid, source, kind) do
    if geometry_references(source, kind) == [] do
      [warning(guid, kind, :geometry_missing) | warnings]
    else
      warnings
    end
  end

  defp geometry_references(source, :fill), do: source.fill_geometry || []
  defp geometry_references(source, :stroke), do: source.stroke_geometry || []

  defp warning(guid, kind, value),
    do: %{guid: GUID.format(guid), feature: kind, value: value}

  defp source_node(scene, guid) do
    source_guid =
      scene.graph.provenance
      |> Map.get(guid, %{})
      |> Map.get(:source_guid, guid)

    Map.get(scene.source_nodes, source_guid)
  end

  defp matrix(nil), do: @identity

  defp matrix(value) do
    {value.m00 || 1.0, value.m01 || 0.0, value.m02 || 0.0, value.m10 || 0.0, value.m11 || 1.0,
     value.m12 || 0.0}
  end

  defp point({a, b, c, d, e, f}, x, y), do: {a * x + b * y + c, d * x + e * y + f}
end
