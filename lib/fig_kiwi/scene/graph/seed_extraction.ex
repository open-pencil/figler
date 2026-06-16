defmodule FigKiwi.Scene.Graph.SeedExtraction do
  @moduledoc false

  alias FigKiwi.Scene.Graph.ComponentPropAssignment
  alias FigKiwi.Scene.Graph.ComponentPropDef
  alias FigKiwi.Scene.Graph.ComponentPropRef
  alias FigKiwi.Scene.Graph.DerivedSymbolData
  alias FigKiwi.Scene.Graph.SeedProjection
  alias FigKiwi.Scene.Graph.SymbolOverride
  alias FigKiwi.Scene.Graph.Value

  def metadata(node_change) do
    SeedProjection.resolver_metadata_fields()
    |> Map.new(&{&1, value(&1, node_change)})
  end

  defp value(field, node_change),
    do: field |> SeedProjection.value_kind() |> value_for(node_change)

  defp value_for(:guid, node_change), do: Value.guid(get(node_change, :override_key))

  defp value_for(:symbol_overrides, node_change),
    do: node_change |> get(:symbol_data) |> symbol_overrides()

  defp value_for(:component_prop_defs, node_change),
    do: node_change |> get(:component_prop_defs) |> component_prop_defs()

  defp value_for(:component_prop_refs, node_change),
    do: node_change |> get(:component_prop_refs) |> component_prop_refs()

  defp value_for(:component_prop_assignments, node_change),
    do: node_change |> get(:component_prop_assignments) |> component_prop_assignments()

  defp value_for(:derived_symbol_data, node_change),
    do: node_change |> get(:derived_symbol_data) |> derived_symbol_data()

  defp value_for({:multiplayer_entries, source_field}, node_change),
    do: node_change |> get(source_field) |> multiplayer_entries()

  defp value_for({:field, field}, node_change), do: get(node_change, field)

  defp symbol_overrides(nil), do: []
  defp symbol_overrides(%{symbol_overrides: nil}), do: []

  defp symbol_overrides(%{symbol_overrides: overrides}) do
    Enum.map(overrides, fn override ->
      %SymbolOverride{
        guid_path: guid_path(get(override, :guid_path)),
        overridden_symbol_id: Value.guid(get(override, :overridden_symbol_id)),
        fields: override_fields(override),
        component_prop_assignments:
          component_prop_assignments(get(override, :component_prop_assignments)),
        variable_consumption: multiplayer_entries(get(override, :variable_consumption_map))
      }
    end)
  end

  defp override_fields(override) do
    %{}
    |> put_present(:name, get(override, :name))
    |> put_present(:visible, get(override, :visible))
    |> put_present(
      :text,
      get(override, :text_data) && get(get(override, :text_data), :characters)
    )
    |> put_present(:size, Value.vector(get(override, :size)))
    |> put_present(:transform, Value.matrix(get(override, :transform)))
  end

  defp component_prop_defs(nil), do: []

  defp component_prop_defs(defs) do
    Enum.map(defs, fn defn ->
      %ComponentPropDef{
        id: Value.guid(get(defn, :id)),
        name: get(defn, :name),
        type: get(defn, :type),
        initial_value: component_prop_value(get(defn, :initial_value))
      }
    end)
  end

  defp component_prop_refs(nil), do: []

  defp component_prop_refs(refs) do
    Enum.map(refs, fn ref ->
      %ComponentPropRef{
        def_id: Value.guid(get(ref, :def_id)),
        field: get(ref, :component_prop_node_field) || get(ref, :node_field)
      }
    end)
  end

  defp component_prop_assignments(nil), do: []

  defp component_prop_assignments(assignments) do
    Enum.map(assignments, fn assignment ->
      %ComponentPropAssignment{
        def_id: Value.guid(get(assignment, :def_id)),
        value: component_prop_value(get(assignment, :value)),
        variable_value: variable_data(get(assignment, :var_value))
      }
    end)
  end

  defp derived_symbol_data(nil), do: []

  defp derived_symbol_data(values) do
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

  defp component_prop_value(nil), do: nil

  defp component_prop_value(value) do
    cond do
      is_boolean(get(value, :bool_value)) -> {:bool, get(value, :bool_value)}
      get(value, :text_value) -> {:text, get(get(value, :text_value), :characters)}
      get(value, :guid_value) -> {:guid, Value.guid(get(value, :guid_value))}
      is_number(get(value, :float_value)) -> {:float, get(value, :float_value)}
      get(value, :vector_value) -> {:vector, Value.vector(get(value, :vector_value))}
      true -> value
    end
  end

  defp variable_data(nil), do: nil
  defp variable_data(data), do: data

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
