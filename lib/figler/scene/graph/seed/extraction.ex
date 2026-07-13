defmodule Figler.Scene.Graph.Seed.Extraction do
  @moduledoc """
  Extracts resolver metadata from generated schema node changes.

  The graph builder uses this module as the boundary between generated Figma
  schema structs and the compact Elixir seed-node metadata consumed by resolver
  stages.
  """

  alias Figler.Scene.Graph.Seed.Extraction.{ComponentProps, DerivedData, SymbolOverrides}
  alias Figler.Scene.Graph.Seed.Projection, as: SeedProjection
  alias Figler.Scene.Graph.Seed.Value

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
    do: node_change |> get(source_field) |> Value.entries()

  defp value_for({:field, field}, node_change), do: get(node_change, field)

  defp get(nil, _key), do: nil
  defp get(map, key) when is_map(map), do: Map.get(map, key)
end
