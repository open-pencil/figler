defmodule Figler.Scene.Graph.Seed.Extraction.SymbolOverrides do
  @moduledoc """
  Extracts symbol override records from generated schema symbol data.

  The extracted overrides describe field changes, component swaps, component
  property assignments, and variable consumption attached to an instance.
  """

  alias Figler.Render.Projection, as: RenderProjection
  alias Figler.Scene.Graph.Seed.Extraction.ComponentProps
  alias Figler.Scene.Graph.Seed.Value

  alias Figler.Scene.Graph.Symbol.Override, as: SymbolOverride

  def all(nil), do: []
  def all(%{symbol_overrides: nil}), do: []

  def all(%{symbol_overrides: overrides}) do
    Enum.map(overrides, fn override ->
      %SymbolOverride{
        guid_path: guid_path(get(override, :guid_path)),
        overridden_symbol_id: Value.guid(get(override, :overridden_symbol_id)),
        fields: fields(override),
        component_prop_assignments:
          ComponentProps.assignments(get(override, :component_prop_assignments)),
        variable_consumption: multiplayer_entries(get(override, :variable_consumption_map))
      }
    end)
  end

  defp fields(override) do
    %{}
    |> put_present(:name, get(override, :name))
    |> put_present(:visible, get(override, :visible))
    |> put_present(
      :text,
      get(override, :text_data) && get(get(override, :text_data), :characters)
    )
    |> put_present(:size, Value.vector(get(override, :size)))
    |> put_present(:transform, Value.matrix(get(override, :transform)))
    |> put_render_fields(override)
  end

  defp put_render_fields(fields, override) do
    RenderProjection.override_field_names()
    |> Kernel.--([:name])
    |> Enum.reduce(fields, fn field, projected ->
      put_present(projected, field, get(override, field))
    end)
  end

  defp multiplayer_entries(nil), do: []
  defp multiplayer_entries(%{entries: entries}) when is_list(entries), do: entries
  defp multiplayer_entries(_value), do: []

  defp put_present(map, _key, nil), do: map
  defp put_present(map, key, value), do: Map.put(map, key, value)

  defp guid_path(nil), do: []
  defp guid_path(%{guids: guids}) when is_list(guids), do: Enum.map(guids, &Value.guid/1)

  defp get(nil, _key), do: nil
  defp get(map, key) when is_map(map), do: Map.get(map, key)
end
