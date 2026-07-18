defmodule Figler.Render.Skia do
  @compile {:no_warn_undefined, [Skia, Skia.ColorFilter, Skia.Document, Skia.ImageFilter]}

  @moduledoc """
  Compiles a `Figler.Render.Scene` into one batched `%Skia.Document{}`.

  Figma decoding and effective graph semantics remain in Figler; drawing and
  raster encoding remain in Skia.
  """

  alias Figler.Render.Affine
  alias Figler.Render.Bounds
  alias Figler.Render.Scene, as: RenderScene
  alias Figler.Render.Skia.Assets
  alias Figler.Render.Skia.Bounds, as: BoundsCompiler
  alias Figler.Render.Skia.Diagnostics
  alias Figler.Render.Skia.Effects
  alias Figler.Render.Skia.Shape
  alias Figler.Scene.Graph.GUID
  alias Figler.Scene.Node

  @container_types ["canvas", "component", "frame", "instance", "symbol"]

  @type bounds :: Bounds.t()

  @doc "Compiles an effective scene into a Skia command document."
  @spec compile(RenderScene.t(), keyword()) ::
          {:ok,
           %{document: Skia.Document.t(), root: String.t(), bounds: bounds(), warnings: [map()]}}
          | {:error, term()}
  def compile(%RenderScene{root: root_guid} = scene, opts \\ []) do
    with {:ok, bounds} <- BoundsCompiler.content(scene, root_guid) do
      compile_root(scene, root_guid, bounds, opts)
    end
  end

  defp compile_root(scene, root_guid, bounds, opts) do
    child_guids = BoundsCompiler.render_guids(scene, root_guid)
    assets = Assets.load(scene)
    warnings = Diagnostics.collect(scene, child_guids, assets)

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
      render_child_sequence(translated, scene, child_guids, assets)
    end)
  end

  defp render_nodes(document, scene, guids, assets) do
    Enum.reduce(guids, document, &render_node(scene, assets, &1, &2))
  end

  defp render_node(scene, assets, guid, document) do
    case Map.get(scene.graph.nodes, guid) do
      %Node{visible: visible} = node when visible != false ->
        source = source_node(scene, guid)

        Skia.group(document, [concat: Affine.from_value(node.transform)], fn transformed ->
          render_transformed(transformed, scene, guid, node, source, assets)
        end)

      _missing_or_hidden ->
        document
    end
  end

  defp render_transformed(document, scene, guid, node, source, assets) do
    resolved = Effects.resolve(source, node.opacity)
    shape_opts = bound_shape_opts(resolved.shape_opts, node, source)

    if resolved.group_opts == [] do
      render_node_content(document, scene, guid, node, source, assets, shape_opts)
    else
      Skia.layer(document, resolved.group_opts, fn layer ->
        render_node_content(layer, scene, guid, node, source, assets, shape_opts)
      end)
    end
  end

  defp bound_shape_opts([], _node, _source), do: []

  defp bound_shape_opts(opts, node, source) do
    Keyword.merge(opts, BoundsCompiler.shape(node, source) |> BoundsCompiler.layer_option())
  end

  defp render_node_content(document, scene, guid, node, source, assets, shape_opts) do
    document
    |> render_shape(node, source, assets, shape_opts)
    |> render_children(scene, node, source, guid, assets)
  end

  defp render_shape(document, node, source, assets, []),
    do: Shape.draw_node(document, node, source, assets)

  defp render_shape(document, node, source, assets, shape_opts) do
    Skia.layer(document, shape_opts, fn layer ->
      Shape.draw_node(layer, node, source, assets)
    end)
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
      |> render_child_sequence(scene, children, assets)
    end
  end

  defp render_child_sequence(document, _scene, [], _assets), do: document

  defp render_child_sequence(document, scene, [guid | rest], assets) do
    case source_node(scene, guid) do
      %{mask: true} ->
        render_mask_sequence(document, scene, [guid | rest], assets)

      _source ->
        document = render_node(scene, assets, guid, document)
        render_child_sequence(document, scene, rest, assets)
    end
  end

  defp render_mask_sequence(document, scene, children, assets) do
    {masks, after_masks} = Enum.split_while(children, &mask_node?(scene, &1))
    {masked, rest} = Enum.split_while(after_masks, &(not mask_node?(scene, &1)))

    document =
      if masked == [] do
        document
      else
        render_mask_group(document, scene, masks, masked, assets)
      end

    render_child_sequence(document, scene, rest, assets)
  end

  defp render_mask_group(document, scene, masks, masked, assets) do
    layer_opts =
      scene
      |> BoundsCompiler.for_guids(masks ++ masked)
      |> BoundsCompiler.layer_option()

    Skia.layer(document, layer_opts, fn content_layer ->
      content_layer = render_nodes(content_layer, scene, masked, assets)
      mask_opts = Keyword.put(layer_opts, :blend_mode, :dst_in)

      Skia.layer(content_layer, mask_opts, fn mask_layer ->
        render_mask_nodes(mask_layer, scene, masks, assets)
      end)
    end)
  end

  defp render_mask_nodes(document, scene, masks, assets) do
    Enum.reduce(masks, document, &render_mask(scene, assets, &1, &2))
  end

  defp render_mask(scene, assets, guid, document) do
    case source_node(scene, guid) do
      %{mask_type: :luminance} ->
        Skia.layer(document, [image_filter: luminance_filter()], fn layer ->
          render_mask_node(layer, scene, guid, assets)
        end)

      _source ->
        render_mask_node(document, scene, guid, assets)
    end
  end

  defp render_mask_node(document, scene, guid, assets) do
    case Map.get(scene.graph.nodes, guid) do
      %Node{visible: visible} = node when visible != false ->
        source = source_node(scene, guid)

        Skia.group(document, [concat: Affine.from_value(node.transform)], fn transformed ->
          Shape.draw_node(transformed, node, source, assets)
        end)

      _missing_or_hidden ->
        document
    end
  end

  defp mask_node?(scene, guid), do: match?(%{mask: true}, source_node(scene, guid))

  defp luminance_filter do
    Skia.ColorFilter.luma()
    |> Skia.ImageFilter.color_filter()
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
  defp source_node(scene, guid), do: Map.get(scene.render_nodes, guid)
end
