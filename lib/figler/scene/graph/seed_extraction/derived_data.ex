defmodule Figler.Scene.Graph.SeedExtraction.DerivedData do
  @moduledoc """
  Extracts derived symbol data from generated schema values.

  Derived data captures geometry, text, sizing, and transform values that Figma
  stores separately from the projected scene node fields.
  """

  alias Figler.Scene.Graph.DerivedSymbolData
  alias Figler.Scene.Graph.Value

  def all(nil), do: []

  def all(values) do
    Enum.map(values, fn value ->
      %DerivedSymbolData{
        guid_path: guid_path(get(value, :guid_path)),
        size: Value.vector(get(value, :size)),
        transform: Value.matrix(get(value, :transform)),
        font_size: get(value, :font_size),
        line_height: get(value, :line_height),
        letter_spacing: get(value, :letter_spacing),
        stroke_weight: get(value, :stroke_weight),
        derived_text_data: get(value, :derived_text_data),
        fill_geometry: get(value, :fill_geometry) || [],
        stroke_geometry: get(value, :stroke_geometry) || []
      }
    end)
  end

  defp guid_path(nil), do: []
  defp guid_path(%{guids: guids}) when is_list(guids), do: Enum.map(guids, &Value.guid/1)

  defp get(nil, _key), do: nil
  defp get(map, key) when is_map(map), do: Map.get(map, key)
end
