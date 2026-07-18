defmodule Figler.Render.Skia.Assets do
  @moduledoc false
  @compile {:no_warn_undefined, [Skia.Image]}

  alias Figler.Render.Geometry
  alias Figler.Render.Skia.Paint

  defstruct images: %{}, errors: %{}, geometries: %{}, geometry_errors: %{}

  @type t :: %__MODULE__{
          images: map(),
          errors: map(),
          geometries: map(),
          geometry_errors: map()
        }

  @spec load(Figler.Render.Scene.t()) :: t()
  def load(scene) do
    scene
    |> load_image_assets()
    |> load_geometry_assets(scene)
  end

  defp load_image_assets(scene) do
    scene.render_nodes
    |> Map.values()
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

  defp load_geometry_assets(assets, scene) do
    Enum.reduce(scene.render_nodes, assets, fn {_guid, node}, loaded ->
      loaded
      |> load_geometry_kind(node, :fill, node.fill_geometry || [], scene.document.blobs)
      |> load_geometry_kind(node, :stroke, node.stroke_geometry || [], scene.document.blobs)
    end)
  end

  defp load_geometry_kind(assets, _node, _kind, [], _blobs), do: assets

  defp load_geometry_kind(assets, node, kind, references, blobs) do
    case Geometry.paths(references, blobs) do
      {:ok, paths} -> put_geometry_result(assets, :geometries, node.guid, kind, paths)
      {:error, reason} -> put_geometry_result(assets, :geometry_errors, node.guid, kind, reason)
    end
  end

  defp put_geometry_result(assets, collection, guid, kind, value) do
    source_values = assets |> Map.fetch!(collection) |> Map.get(guid, %{}) |> Map.put(kind, value)
    Map.update!(assets, collection, &Map.put(&1, guid, source_values))
  end
end
