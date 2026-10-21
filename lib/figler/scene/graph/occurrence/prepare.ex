defmodule Figler.Scene.Graph.Occurrence.Prepare do
  @moduledoc false

  # Normalizes records before interpretation, as OpenPencil's reader does:
  #
  #   * current files bind component properties through `parameterConsumptionMap`
  #     entries of type PROP_REF and keep defaults in `varValue`; both are
  #     adapted to `componentPropRefs` and `initialValue`;
  #   * a property definition naming `parentPropDefId` is completed from the
  #     nearest ancestor that defines it. OpenPencil rejects a document whose
  #     parent is missing; Figler keeps the definition as saved;
  #   * a record, and each of its override records, takes the paints, effects,
  #     layout grids, or text fields of the shared styles it references.

  alias Figler.Scene.Graph.Occurrence.GUID

  @bound_fields [:visible, :text_data, :overridden_symbol_id, :slot_content_id]

  @doc "Prepares live records for indexing."
  @spec records([map()], boolean()) :: [map()]
  def records(records, styles? \\ true) do
    records = records |> Enum.map(&normalize/1) |> inherit_property_definitions()
    if styles?, do: apply_styles(records), else: records
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

      # Only definitions that name a parent take anything from ancestors.
      not linked_definitions?(record) ->
        {record, Map.put(cache, id, record)}

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

  @text_style_fields [:font_size, :font_name, :line_height, :letter_spacing, :text_case]

  defp apply_styles(records) do
    styles =
      for %{style_type: type} = record <- records,
          type != nil,
          into: %{},
          do: {GUID.key(record.guid), record}

    if styles == %{} do
      records
    else
      keys = style_keys(records)
      Enum.map(records, &apply_style_refs(&1, styles, keys))
    end
  end

  # Library styles are named by key, and by key and version.
  defp style_keys(records) do
    for %{key: key} = record <- records, is_binary(key), reduce: %{} do
      keys ->
        id = GUID.key(record.guid)
        keys = Map.put(keys, key, id)
        version = Map.get(record, :version)
        if is_binary(version), do: Map.put(keys, "#{key}@#{version}", id), else: keys
    end
  end

  defp apply_style_refs(record, styles, keys) do
    record
    |> style_field(
      :style_id_for_fill,
      :fill,
      styles,
      keys,
      &Map.put(&1, :fill_paints, &2.fill_paints)
    )
    |> style_field(
      :style_id_for_stroke_fill,
      :fill,
      styles,
      keys,
      &Map.put(&1, :stroke_paints, &2.fill_paints)
    )
    |> style_field(
      :style_id_for_effect,
      :effect,
      styles,
      keys,
      &Map.put(&1, :effects, &2.effects)
    )
    |> style_field(
      :style_id_for_grid,
      :grid,
      styles,
      keys,
      &Map.put(&1, :layout_grids, &2.layout_grids)
    )
    |> text_style(styles, keys)
    |> update_list([:symbol_data, :symbol_overrides], &apply_style_refs(&1, styles, keys))
  end

  @style_sources %{fill: :fill_paints, effect: :effects, grid: :layout_grids}

  defp style_field(record, field, style_type, styles, keys, put) do
    case referenced_style(record, field, styles, keys) do
      %{style_type: ^style_type} = style
      when is_map_key(style, :erlang.map_get(style_type, @style_sources)) ->
        put.(record, style)

      _other ->
        record
    end
  end

  # A text style sets the fields it defines, and its decoration even when unset.
  defp text_style(record, styles, keys) do
    case referenced_style(record, :style_id_for_text, styles, keys) do
      %{type: :text, style_type: :text} = style ->
        record
        |> Map.merge(Map.take(style, @text_style_fields))
        |> Map.put(:text_decoration, Map.get(style, :text_decoration))
        |> Map.reject(fn {field, value} -> field == :text_decoration and is_nil(value) end)

      _other ->
        record
    end
  end

  defp referenced_style(record, field, styles, keys) do
    case Map.get(record, field) do
      %{guid: guid} when guid != nil ->
        Map.get(styles, GUID.key(guid))

      %{asset_ref: %{key: key} = asset} ->
        version = Map.get(asset, :version)
        id = (version && Map.get(keys, "#{key}@#{version}")) || Map.get(keys, key)
        id && Map.get(styles, id)

      _none ->
        nil
    end
  end
end
