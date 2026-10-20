defmodule Figler.Scene.Graph.Occurrence.Prepare do
  @moduledoc false

  # Normalizes records before interpretation, as OpenPencil's reader does:
  #
  #   * current files bind component properties through `parameterConsumptionMap`
  #     entries of type PROP_REF and keep defaults in `varValue`; both are
  #     adapted to `componentPropRefs` and `initialValue`;
  #   * a property definition naming `parentPropDefId` is completed from the
  #     nearest ancestor that defines it. OpenPencil rejects a document whose
  #     parent is missing; Figler keeps the definition as saved.

  alias Figler.Scene.Graph.Occurrence.GUID

  @bound_fields [:visible, :text_data, :overridden_symbol_id, :slot_content_id]

  @doc "Prepares live records for indexing."
  @spec records([map()]) :: [map()]
  def records(records) do
    records = Enum.map(records, &normalize/1)
    inherit_property_definitions(records)
  end

  # Applies to a record, its override and derived records, and its text ranges.
  defp normalize(record) do
    record
    |> normalize_property_records()
    |> update_list([:symbol_data, :symbol_overrides], &normalize/1)
    |> update_list([:derived_symbol_data], &normalize/1)
    |> update_list([:text_data, :style_override_table], &normalize/1)
  end

  defp normalize_property_records(record) do
    record
    |> update_list([:component_prop_defs], &normalize_default/1)
    |> put_prop_refs()
  end

  defp normalize_default(%{initial_value: value} = definition) when value != nil, do: definition

  defp normalize_default(definition) do
    case get_in(definition, [:var_value, :value]) do
      nil ->
        definition

      %{symbol_id_value: %{guid: guid}} when guid != nil ->
        Map.put(definition, :initial_value, %{guid_value: guid})

      value ->
        Map.put(definition, :initial_value, value)
    end
  end

  # A PROP_REF entry replaces the saved ref for the same field. Refs are kept in
  # reverse while merging, so a replacement keeps its position.
  defp put_prop_refs(record) do
    refs =
      record
      |> get_in([:parameter_consumption_map, :entries])
      |> List.wrap()
      |> Enum.flat_map(&prop_ref/1)
      |> Enum.reduce(Enum.reverse(Map.get(record, :component_prop_refs) || []), &upsert_ref/2)
      |> Enum.reverse()

    if refs == [], do: record, else: Map.put(record, :component_prop_refs, refs)
  end

  defp prop_ref(%{variable_field: field, variable_data: %{data_type: :prop_ref} = variable})
       when field in @bound_fields do
    case get_in(variable, [:value, :prop_ref_value, :def_id]) do
      nil -> []
      def_id -> [%{def_id: def_id, component_prop_node_field: field}]
    end
  end

  defp prop_ref(_entry), do: []

  defp upsert_ref(ref, refs) do
    field = ref.component_prop_node_field

    case Enum.find_index(refs, &(Map.get(&1, :component_prop_node_field) == field)) do
      nil -> [ref | refs]
      index -> List.replace_at(refs, index, ref)
    end
  end

  defp update_list(map, path, fun) do
    case get_in(map, path) do
      list when is_list(list) -> put_in(map, path, Enum.map(list, fun))
      _missing -> map
    end
  end

  # Completes definitions that name a parent from the nearest ancestor holding it.
  defp inherit_property_definitions(records) do
    by_id = Map.new(records, &{GUID.key(Map.get(&1, :guid)), &1})

    if Enum.any?(records, &linked_definitions?/1) do
      {resolved, _cache} =
        Enum.map_reduce(records, %{}, fn record, cache ->
          resolve(record, by_id, cache, MapSet.new())
        end)

      resolved
    else
      records
    end
  end

  defp linked_definitions?(record) do
    record
    |> Map.get(:component_prop_defs)
    |> List.wrap()
    |> Enum.any?(&Map.get(&1, :parent_prop_def_id))
  end

  defp resolve(record, by_id, cache, visiting) do
    id = GUID.key(Map.get(record, :guid))

    cond do
      Map.has_key?(cache, id) ->
        {Map.fetch!(cache, id), cache}

      MapSet.member?(visiting, id) ->
        raise ArgumentError, "cyclic component-property ancestry"

      true ->
        {ancestors, cache} = resolved_ancestors(record, by_id, cache, MapSet.put(visiting, id))
        resolved = inherit_from(record, ancestors)
        {resolved, Map.put(cache, id, resolved)}
    end
  end

  defp resolved_ancestors(record, by_id, cache, visiting) do
    case Map.get(by_id, record |> get_in([:parent_index, :guid]) |> GUID.key()) do
      nil ->
        {[], cache}

      parent ->
        {parent, cache} = resolve(parent, by_id, cache, visiting)
        {ancestors, cache} = resolved_ancestors(parent, by_id, cache, visiting)
        {[parent | ancestors], cache}
    end
  end

  # A definition whose parent is not among its ancestors, as in a partial set
  # of records, keeps its own fields.
  defp inherit_from(record, ancestors) do
    update_list(record, [:component_prop_defs], fn definition ->
      case GUID.key(Map.get(definition, :parent_prop_def_id)) do
        nil -> definition
        parent_id -> Map.merge(parent_definition(ancestors, parent_id), definition)
      end
    end)
  end

  defp parent_definition(ancestors, parent_id) do
    Enum.find_value(ancestors, %{}, fn ancestor ->
      case Enum.filter(
             List.wrap(Map.get(ancestor, :component_prop_defs)),
             &(GUID.key(Map.get(&1, :id)) == parent_id)
           ) do
        [] -> nil
        [definition] -> definition
        _many -> raise ArgumentError, "ambiguous parent property #{GUID.format(parent_id)}"
      end
    end)
  end
end
