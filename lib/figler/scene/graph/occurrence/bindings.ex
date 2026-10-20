defmodule Figler.Scene.Graph.Occurrence.Bindings do
  @moduledoc false

  # Component property values belong to one component expansion: a component
  # definition starts a scope with its defaults, and the instance's assignments
  # replace them. Records inside bind their fields through componentPropRefs.

  alias Figler.Scene.Graph.Occurrence.GUID

  @type binding :: %{
          id: GUID.t(),
          value: map(),
          origin: :default | :assignment,
          rank: non_neg_integer() | nil,
          superseded: [map()]
        }

  @doc "The defaults a component definition binds for its own expansion."
  @spec component([map()] | nil) :: [binding()]
  def component(definitions) do
    for definition <- definitions || [],
        id = GUID.key(Map.get(definition, :id)),
        value = Map.get(definition, :initial_value),
        do: %{id: id, value: value, origin: :default, rank: nil, superseded: []}
  end

  @doc "Applies an owner's assignments over `bindings`; later entries win."
  @spec assign([binding()], [map()], non_neg_integer() | nil) :: [binding()]
  def assign(bindings, assignments, rank) do
    assignments
    |> Enum.flat_map(&assignment_binding(&1, rank))
    |> Enum.reduce(Enum.reverse(bindings), &replace/2)
    |> Enum.reverse()
  end

  defp assignment_binding(assignment, rank) do
    with id when id != nil <- GUID.key(Map.get(assignment, :def_id)),
         value when value != nil <- assignment_value(assignment) do
      [%{id: id, value: value, origin: :assignment, rank: rank, superseded: []}]
    else
      _missing -> []
    end
  end

  # Bindings are reversed while assigning; a replacement keeps its position and
  # remembers the values it replaced, innermost first.
  defp replace(binding, bindings) do
    case Enum.find_index(bindings, &(&1.id == binding.id)) do
      nil ->
        [binding | bindings]

      index ->
        List.update_at(bindings, index, fn previous ->
          %{binding | superseded: previous.superseded ++ [previous.value]}
        end)
    end
  end

  @value_fields [:bool_value, :text_value, :guid_value, :text_data_value]
  @variable_fields [:bool_value, :text_value, :text_data_value, :slot_content_id_value]

  defp assignment_value(assignment) do
    value = Map.get(assignment, :value) || %{}
    variable = get_in(assignment, [:var_value, :value]) || %{}

    cond do
      Enum.any?(@value_fields, &Map.has_key?(value, &1)) -> value
      guid = get_in(variable, [:symbol_id_value, :guid]) -> %{guid_value: guid}
      true -> variable_value(variable)
    end
  end

  defp variable_value(variable) do
    Enum.find_value(@variable_fields, fn field ->
      if Map.has_key?(variable, field), do: Map.take(variable, [field])
    end)
  end

  @doc "The content frame a slot value names, unless it names the component's own content."
  @spec slot_content(map() | nil) :: GUID.t() | nil
  def slot_content(value) do
    guid = get_in(value || %{}, [:slot_content_id_value, :guid])
    if guid && not GUID.unset?(guid), do: GUID.key(guid)
  end

  @doc """
  Binds a record's fields from the enclosing scope.

  Returns the bound record and `{claim, binding}` pairs, where a claim names the
  field the binding set: `:visible`, `:text_data`, `:symbol_data`, or
  `:slot_content`.
  """
  @spec bind(map(), [binding()]) :: {map(), [{map(), binding()}]}
  def bind(record, bindings) do
    {record, claims} =
      record
      |> Map.get(:component_prop_refs, [])
      |> Enum.reduce({record, []}, &bind_ref(&1, &2, bindings))

    {record, Enum.reverse(claims)}
  end

  defp bind_ref(ref, {record, claims}, bindings) do
    with false <- Map.get(ref, :is_deleted, false),
         id when id != nil <- GUID.key(Map.get(ref, :def_id)),
         %{} = binding <- Enum.find(bindings, &(&1.id == id)),
         {record, field} when field != nil <- bind_field(record, ref, binding.value) do
      claim = %{definition_id: id, field: field, origin: binding.origin}
      {record, [{claim, binding} | claims]}
    else
      _unbound -> {record, claims}
    end
  end

  defp bind_field(record, %{component_prop_node_field: :visible}, %{bool_value: visible})
       when is_boolean(visible),
       do: {Map.put(record, :visible, visible), :visible}

  defp bind_field(record, %{component_prop_node_field: :text_data}, value) do
    case text_value(value) do
      nil ->
        {record, nil}

      text ->
        text_data = Map.get(record, :text_data) || %{}

        record =
          if text != Map.get(text_data, :characters),
            do: Map.delete(record, :derived_text_data),
            else: record

        {Map.put(record, :text_data, Map.put(text_data, :characters, text)), :text_data}
    end
  end

  defp bind_field(record, %{component_prop_node_field: :overridden_symbol_id}, %{guid_value: guid})
       when guid != nil do
    symbol_data = Map.get(record, :symbol_data) || %{}
    {Map.put(record, :symbol_data, Map.put(symbol_data, :symbol_id, guid)), :symbol_data}
  end

  # The record keeps its fields; the expansion reads the content from the binding.
  defp bind_field(record, %{component_prop_node_field: :slot_content_id}, %{
         slot_content_id_value: value
       })
       when value != nil,
       do: {record, :slot_content}

  defp bind_field(record, _ref, _value), do: {record, nil}

  defp text_value(%{text_value: text}) when is_binary(text), do: text
  defp text_value(%{text_value: %{characters: text}}) when is_binary(text), do: text
  defp text_value(%{text_data_value: %{characters: text}}) when is_binary(text), do: text
  defp text_value(_value), do: nil
end
