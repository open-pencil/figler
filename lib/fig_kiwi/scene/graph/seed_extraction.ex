defmodule FigKiwi.Scene.Graph.SeedExtraction do
  @moduledoc false

  alias FigKiwi.Scene.Graph.SeedExtraction.ComponentProps
  alias FigKiwi.Scene.Graph.SeedExtraction.DerivedData
  alias FigKiwi.Scene.Graph.SeedExtraction.SymbolOverrides
  alias FigKiwi.Scene.Graph.SeedProjection
  alias FigKiwi.Scene.Graph.Value

  def metadata(node_change) do
    SeedProjection.resolver_metadata_fields()
    |> Map.new(&{&1, value(&1, node_change)})
  end

  defp value(field, node_change),
    do: field |> SeedProjection.value_kind() |> value_for(node_change)

  defp value_for(:guid, node_change), do: Value.guid(get(node_change, :override_key))

  defp value_for(:symbol_overrides, node_change),
    do: node_change |> get(:symbol_data) |> SymbolOverrides.all()

  defp value_for(:component_prop_defs, node_change),
    do: node_change |> get(:component_prop_defs) |> ComponentProps.defs()

  defp value_for(:component_prop_refs, node_change),
    do: node_change |> get(:component_prop_refs) |> ComponentProps.refs()

  defp value_for(:component_prop_assignments, node_change),
    do: node_change |> get(:component_prop_assignments) |> ComponentProps.assignments()

  defp value_for(:derived_symbol_data, node_change),
    do: node_change |> get(:derived_symbol_data) |> DerivedData.all()

  defp value_for({:multiplayer_entries, source_field}, node_change),
    do: node_change |> get(source_field) |> multiplayer_entries()

  defp value_for({:field, field}, node_change), do: get(node_change, field)

  defp multiplayer_entries(nil), do: []
  defp multiplayer_entries(%{entries: entries}) when is_list(entries), do: entries
  defp multiplayer_entries(_value), do: []

  defp get(nil, _key), do: nil
  defp get(map, key) when is_map(map), do: Map.get(map, key)
end
