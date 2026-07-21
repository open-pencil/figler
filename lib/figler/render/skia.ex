defmodule Figler.Render.Skia do
  @compile {:no_warn_undefined, [Skia, Skia.ColorFilter, Skia.Document, Skia.ImageFilter]}

  @moduledoc """
  Compiles a `Figler.Render.Scene` into one batched `%Skia.Document{}`.

  Figma decoding and effective graph semantics remain in Figler; drawing and
  raster encoding remain in Skia.
  """

  alias Figler.Render.Affine
  alias Figler.Render.Bounds
  alias Figler.Render.Node
  alias Figler.Render.Scene, as: RenderScene
  alias Figler.Render.Skia.Assets
  alias Figler.Render.Skia.Bounds, as: BoundsCompiler
  alias Figler.Render.Skia.Diagnostics
  alias Figler.Render.Skia.Effects
  alias Figler.Render.Skia.Shape
  alias Figler.Render.Warning
  alias Figler.Scene.Graph.GUID

  @type bounds :: Bounds.t()

  @max_output_dimension 16_384
  @max_output_pixels 67_108_864

  @doc "Compiles an effective scene into a Skia command document."
  @spec compile(RenderScene.t(), keyword()) ::
          {:ok,
           %{
             document: Skia.Document.t(),
             root: String.t(),
             bounds: bounds(),
             warnings: [Warning.t()]
           }}
          | {:error, term()}
  def compile(%RenderScene{root: root_guid} = scene, opts \\ []) do
    with {:ok, bounds} <- content_bounds(scene, root_guid, opts) do
      compile_root(scene, root_guid, bounds, opts)
    end
  end

  defp content_bounds(scene, root_guid, opts) do
    BoundsCompiler.content(scene, root_guid)
  rescue
    ArithmeticError -> invalid_bounds(:non_finite, nil, render_scale(opts))
  end

  defp compile_root(scene, root_guid, bounds, opts) do
    child_guids = BoundsCompiler.render_guids(scene, root_guid)

    with {:ok, dimensions} <- output_dimensions(bounds, opts),
         {:ok, assets} <- Assets.load(scene, child_guids, opts) do
      warnings = Diagnostics.collect(scene, child_guids, assets)

      if Keyword.get(opts, :strict, false) and warnings != [] do
        {:error, {:unsupported_render_features, warnings}}
      else
        document = build_document(scene, child_guids, bounds, dimensions, assets, opts)

        {:ok,
         %{
           document: document,
           root: GUID.format(root_guid),
           bounds: bounds,
           warnings: warnings
         }}
      end
    end
  end

  defp build_document(scene, child_guids, bounds, {width, height}, assets, opts) do
    scale = opts |> Keyword.get(:scale, 1.0) |> :erlang.float()

    width
    |> Skia.canvas(height)
    |> Skia.clear(Keyword.get(opts, :background, :transparent))
    |> Skia.group([scale: {scale, scale}], fn scaled ->
      render_scaled(scaled, scene, child_guids, bounds, assets)
    end)
  end

  defp output_dimensions(%Bounds{} = bounds, opts) do
    scale = render_scale(opts)
    width = (bounds.max_x - bounds.min_x) * scale
    height = (bounds.max_y - bounds.min_y) * scale

    cond do
      not finite?(width) or not finite?(height) ->
        invalid_bounds(:non_finite, bounds, scale)

      width < 0 or height < 0 ->
        invalid_bounds(:negative_extent, bounds, scale)

      width > @max_output_dimension or height > @max_output_dimension ->
        invalid_bounds(:output_too_large, bounds, scale, width, height)

      true ->
        validate_rounded_dimensions(bounds, scale, width, height)
    end
  rescue
    ArithmeticError -> invalid_bounds(:non_finite, bounds, render_scale(opts))
  end

  defp validate_rounded_dimensions(bounds, scale, width, height) do
    dimensions = {max(1, ceil(width)), max(1, ceil(height))}

    case dimensions do
      {rounded_width, rounded_height}
      when rounded_width * rounded_height > @max_output_pixels ->
        invalid_bounds(:output_too_large, bounds, scale, width, height)

      _safe ->
        {:ok, dimensions}
    end
  end

  defp invalid_bounds(reason, bounds, scale, width \\ nil, height \\ nil) do
    {:error,
     {:invalid_render_bounds,
      %{
        reason: reason,
        bounds: bounds_value(bounds),
        scale: scale,
        output_width: width,
        output_height: height,
        max_output_dimension: @max_output_dimension,
        max_output_pixels: @max_output_pixels
      }}}
  end

  defp bounds_value(%Bounds{} = bounds), do: Map.from_struct(bounds)
  defp bounds_value(nil), do: nil

  defp render_scale(opts), do: opts |> Keyword.get(:scale, 1.0) |> :erlang.float()

  defp finite?(value) do
    encoded = :erlang.float_to_binary(value, [:compact])
    encoded not in ["nan", "inf", "-inf"]
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
    case Map.get(scene.render_nodes, guid) do
      %Node{visible: visible} = node when visible != false ->
        Skia.group(document, [concat: Affine.from_value(node.transform)], fn transformed ->
          render_transformed(transformed, scene, node, assets)
        end)

      _missing_or_hidden ->
        document
    end
  end

  defp render_transformed(document, scene, node, assets) do
    resolved = Effects.resolve(node, node.opacity)
    shape_opts = bound_shape_opts(resolved.shape_opts, node)
    group_opts = bound_group_opts(resolved.group_opts, scene, node)

    if group_opts == [] do
      render_node_content(document, scene, node, assets, shape_opts, resolved)
    else
      Skia.layer(document, group_opts, fn layer ->
        render_node_content(layer, scene, node, assets, shape_opts, resolved)
      end)
    end
  end

  defp bound_group_opts([], _scene, _node), do: []

  defp bound_group_opts(opts, scene, node) do
    Keyword.merge(
      opts,
      BoundsCompiler.local_subtree(scene, node) |> BoundsCompiler.layer_option()
    )
  end

  defp bound_shape_opts([], _node), do: []

  defp bound_shape_opts(opts, node) do
    Keyword.merge(opts, BoundsCompiler.shape(node) |> BoundsCompiler.layer_option())
  end

  defp render_node_content(document, scene, node, assets, shape_opts, resolved) do
    document
    |> Effects.render_background_blurs(node, assets, resolved)
    |> render_shape(node, assets, shape_opts)
    |> Effects.render_inner_shadows(node, assets, resolved)
    |> render_children(scene, node, assets)
  end

  defp render_shape(document, node, assets, []),
    do: Shape.draw_node(document, node, assets)

  defp render_shape(document, node, assets, shape_opts) do
    Skia.layer(document, shape_opts, fn layer ->
      Shape.draw_node(layer, node, assets)
    end)
  end

  defp render_children(document, _scene, %Node{node_type: :boolean_operation}, _assets),
    do: document

  defp render_children(document, scene, node, assets) do
    children = Map.get(scene.children, node.guid, [])

    if children == [] do
      document
    else
      document
      |> maybe_clip(node)
      |> render_child_sequence(scene, children, assets)
    end
  end

  defp render_child_sequence(document, _scene, [], _assets), do: document

  defp render_child_sequence(document, scene, [guid | rest], assets) do
    case Map.get(scene.render_nodes, guid) do
      %Node{mask: true} ->
        render_mask_sequence(document, scene, [guid | rest], assets)

      _node ->
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
    case Map.get(scene.render_nodes, guid) do
      %Node{mask_type: :luminance} ->
        Skia.layer(document, [image_filter: luminance_filter()], fn layer ->
          render_mask_node(layer, scene, guid, assets)
        end)

      _node ->
        render_mask_node(document, scene, guid, assets)
    end
  end

  defp render_mask_node(document, scene, guid, assets) do
    case Map.get(scene.render_nodes, guid) do
      %Node{visible: visible} = node when visible != false ->
        Skia.group(document, [concat: Affine.from_value(node.transform)], fn transformed ->
          render_mask_transformed(transformed, node, assets)
        end)

      _missing_or_hidden ->
        document
    end
  end

  defp render_mask_transformed(document, node, assets) do
    resolved = Effects.resolve(node, node.opacity)
    shape_opts = bound_shape_opts(resolved.shape_opts, node)
    group_opts = bound_mask_group_opts(resolved.group_opts, node)

    render = fn layer ->
      layer
      |> Effects.render_background_blurs(node, assets, resolved)
      |> render_shape(node, assets, shape_opts)
      |> Effects.render_inner_shadows(node, assets, resolved)
    end

    if group_opts == [], do: render.(document), else: Skia.layer(document, group_opts, render)
  end

  defp bound_mask_group_opts([], _node), do: []

  defp bound_mask_group_opts(opts, node) do
    Keyword.merge(opts, BoundsCompiler.shape(node) |> BoundsCompiler.layer_option())
  end

  defp mask_node?(scene, guid), do: match?(%Node{mask: true}, Map.get(scene.render_nodes, guid))

  defp luminance_filter do
    Skia.ColorFilter.luma()
    |> Skia.ImageFilter.color_filter()
  end

  defp maybe_clip(document, %Node{} = node) do
    if Node.clips_children?(node), do: Shape.clip_children(document, node), else: document
  end
end
