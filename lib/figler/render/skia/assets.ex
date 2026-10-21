defmodule Figler.Render.Skia.Assets do
  @moduledoc false
  @compile {:no_warn_undefined, [Skia.Image, Skia.Path]}

  alias Figler.Render.Geometry
  alias Figler.Render.Skia.Fonts
  alias Figler.Render.Skia.Paint
  alias Figler.Render.Skia.VectorNetwork, as: SkiaVectorNetwork
  alias Figler.Render.Text.Glyphs
  alias Figler.Render.VectorNetwork

  defstruct images: %{},
            errors: %{},
            geometries: %{},
            geometry_errors: %{},
            vector_geometries: %{},
            vector_networks: %{},
            vector_network_errors: %{},
            text_glyphs: %{},
            fonts: %{},
            font_spans: %{},
            font_warnings: %{}

  @type t :: %__MODULE__{
          images: map(),
          errors: map(),
          geometries: map(),
          geometry_errors: map(),
          vector_geometries: map(),
          vector_networks: %{optional(tuple()) => VectorNetwork.t()},
          vector_network_errors: %{optional(tuple()) => term()},
          text_glyphs: %{optional(tuple()) => [{Figler.Render.Text.Run.t() | nil, Skia.Path.t()}]},
          fonts: %{optional(tuple()) => Figler.Render.Skia.Fonts.Resolved.t()},
          font_spans: %{optional(tuple()) => [Figler.Render.Skia.Fonts.Span.t()]},
          font_warnings: %{optional(tuple()) => [map()]}
        }

  @spec load(Figler.Render.Scene.t(), [tuple()], keyword()) :: {:ok, t()} | {:error, term()}
  def load(scene, root_guids, opts) do
    nodes = selected_nodes(scene, root_guids)

    assets =
      scene
      |> load_image_assets(nodes)
      |> load_geometry_assets(nodes, scene.document.blobs)
      |> load_vector_network_assets(nodes, scene.document.blobs)
      |> load_text_glyph_assets(nodes, scene.document.blobs)

    # Text drawn from its saved glyphs needs no font.
    laid_out = Enum.reject(nodes, &Map.has_key?(assets.text_glyphs, &1.guid))

    with {:ok, font_assets} <- Fonts.resolve(laid_out, opts) do
      {:ok,
       %{
         assets
         | fonts: font_assets.fonts,
           font_spans: font_assets.spans,
           font_warnings: font_assets.warnings
       }}
    end
  end

  defp selected_nodes(scene, root_guids) do
    {nodes, _seen} =
      Enum.reduce(root_guids, {[], MapSet.new()}, fn guid, collected ->
        collect_node(scene, guid, collected)
      end)

    Enum.reverse(nodes)
  end

  defp collect_node(scene, guid, {nodes, seen}) do
    if MapSet.member?(seen, guid) do
      {nodes, seen}
    else
      collect_unseen_node(scene, guid, {nodes, MapSet.put(seen, guid)})
    end
  end

  defp collect_unseen_node(scene, guid, collected) do
    scene.render_nodes
    |> Map.fetch(guid)
    |> collect_render_node(scene, guid, collected)
  end

  defp collect_render_node(:error, _scene, _guid, collected), do: collected

  defp collect_render_node({:ok, node}, scene, guid, {nodes, seen}) do
    scene.children
    |> Map.get(guid, [])
    |> Enum.reduce({[node | nodes], seen}, fn child_guid, collected ->
      collect_node(scene, child_guid, collected)
    end)
  end

  defp load_image_assets(scene, nodes) do
    nodes
    |> Enum.flat_map(&node_image_keys/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.reduce(%__MODULE__{}, &load_image_asset(scene, &1, &2))
  end

  defp node_image_keys(node) do
    [node.fill_paints || [], node.stroke_paints || []]
    |> Enum.flat_map(&Enum.map(&1, fn paint -> Paint.image_key(paint) end))
  end

  defp load_image_asset(scene, key, assets) do
    with data when is_binary(data) <- find_image_asset(scene.document, key),
         {:ok, image} <- Skia.Image.decode(data) do
      put_in(assets, [Access.key(:images), key], image)
    else
      nil ->
        put_in(assets, [Access.key(:errors), key], :missing_image_asset)

      {:error, reason} ->
        put_in(assets, [Access.key(:errors), key], {:invalid_image_asset, reason})
    end
  end

  defp find_image_asset(document, {:blob, index}), do: Enum.at(document.blobs, index)

  defp find_image_asset(document, hash) do
    Map.get(document.images, hash) ||
      Enum.find_value(document.images, fn {path, data} ->
        if path |> Path.basename() |> Path.rootname() |> String.downcase() == hash, do: data
      end)
  end

  defp load_geometry_assets(assets, nodes, blobs) do
    Enum.reduce(nodes, assets, fn node, loaded ->
      loaded
      |> load_geometry_kind(node, :fill, node.fill_geometry || [], blobs)
      |> load_geometry_kind(node, :stroke, node.stroke_geometry || [], blobs)
    end)
  end

  defp load_geometry_kind(assets, _node, _kind, [], _blobs), do: assets

  defp load_geometry_kind(assets, node, kind, references, blobs) do
    case Geometry.paths(references, blobs) do
      {:ok, paths} -> put_geometry_result(assets, :geometries, node.guid, kind, paths)
      {:error, reason} -> put_geometry_result(assets, :geometry_errors, node.guid, kind, reason)
    end
  end

  defp load_vector_network_assets(assets, nodes, blobs) do
    Enum.reduce(nodes, assets, &load_vector_network_asset(&2, &1, blobs))
  end

  defp load_vector_network_asset(assets, %{vector_network: nil}, _blobs), do: assets

  defp load_vector_network_asset(assets, node, blobs) do
    reference = node.vector_network

    with index when is_integer(index) <- reference.blob_index,
         blob when is_binary(blob) <- Enum.at(blobs, index),
         {:ok, network} <- VectorNetwork.decode(blob, reference.normalized_size, node.size),
         {:ok, paths} <- SkiaVectorNetwork.paths(network) do
      assets
      |> put_in([Access.key(:vector_networks), node.guid], network)
      |> put_in([Access.key(:vector_geometries), node.guid], paths)
    else
      nil -> put_vector_network_error(assets, node.guid, :missing_vector_network_blob)
      {:error, reason} -> put_vector_network_error(assets, node.guid, reason)
    end
  end

  defp load_text_glyph_assets(assets, nodes, blobs) do
    blobs = List.to_tuple(blobs)

    Enum.reduce(nodes, assets, fn
      %{text: %{} = text} = node, loaded ->
        with true <- Glyphs.drawable?(text, node.fill_paints || []),
             {:ok, paths} <- glyph_paths(text, blobs) do
          put_in(loaded, [Access.key(:text_glyphs), node.guid], paths)
        else
          _laid_out -> loaded
        end

      _node, loaded ->
        loaded
    end)
  end

  # One path per run of glyphs painted alike. A glyph whose outline is missing leaves the text
  # to be laid out instead, as drawing it would leave a gap.
  defp glyph_paths(text, blobs) do
    text
    |> Glyphs.placements()
    |> Enum.reduce_while({:ok, []}, fn {run, placed}, {:ok, paths} ->
      case glyph_path(placed, blobs) do
        {:ok, path} -> {:cont, {:ok, [{run, path} | paths]}}
        error -> {:halt, error}
      end
    end)
    |> then(fn
      {:ok, paths} -> {:ok, Enum.reverse(paths)}
      error -> error
    end)
  end

  defp glyph_path(placed, blobs) do
    Enum.reduce_while(placed, {:ok, Skia.Path.new()}, fn {glyph, matrix}, {:ok, path} ->
      with true <- glyph.commands_blob < tuple_size(blobs),
           {:ok, path} <- Geometry.append(path, elem(blobs, glyph.commands_blob), matrix) do
        {:cont, {:ok, path}}
      else
        false -> {:halt, {:error, :missing_glyph_blob}}
        error -> {:halt, error}
      end
    end)
  end

  defp put_vector_network_error(assets, guid, reason),
    do: put_in(assets, [Access.key(:vector_network_errors), guid], reason)

  defp put_geometry_result(assets, collection, guid, kind, value) do
    source_values = assets |> Map.fetch!(collection) |> Map.get(guid, %{}) |> Map.put(kind, value)
    Map.update!(assets, collection, &Map.put(&1, guid, source_values))
  end
end
