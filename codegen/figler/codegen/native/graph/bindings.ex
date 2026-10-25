defmodule Figler.Codegen.Native.Graph.Bindings do
  @moduledoc """
  Component property bindings for the native interpreter.

  Following OpenPencil's reader, a component definition starts a scope with its defaults, and
  the instance's assignments replace them. Records inside bind their fields through
  `componentPropRefs`.

  A value comes from a `ComponentPropValue` or from a variable's value; `prop_value` keeps the
  parts binding reads from either.
  """

  use RustQ.Meta,
    callable_modules: [
      Figler.Codegen.Native.Graph.Records,
      Figler.Codegen.Native.Graph.Occurrence
    ]

  alias Figler.Codegen.Native.Graph.Occurrence
  alias KiwiCodec.RustlerGenerator.Records, as: Kiwi
  alias RustQ.Type, as: R

  defrustmod NodeChange, as: [:kiwi_records, :node_change]
  defrustmod SymbolData, as: [:kiwi_records, :symbol_data]
  defrustmod TextData, as: [:kiwi_records, :text_data]
  defrustmod ComponentPropDef, as: [:kiwi_records, :component_prop_def]
  defrustmod ComponentPropRef, as: [:kiwi_records, :component_prop_ref]
  defrustmod ComponentPropValue, as: [:kiwi_records, :component_prop_value]
  defrustmod ComponentPropAssignment, as: [:kiwi_records, :component_prop_assignment]
  defrustmod ComponentPropNodeField, as: [:kiwi_records, :component_prop_node_field]
  defrustmod VariableData, as: [:kiwi_records, :variable_data]
  defrustmod VariableAnyValue, as: [:kiwi_records, :variable_any_value]
  defrustmod SymbolId, as: [:kiwi_records, :symbol_id]
  defrustmod SlotContentId, as: [:kiwi_records, :slot_content_id]
  defrustmod Definitions, as: [:kiwi_record_definitions]

  @typep prop_value :: %{
           required(:bool) => R.option(R.bool()),
           required(:text) => R.option(String.t()),
           required(:guid) => R.option(Kiwi.kiwi_record()),
           required(:has_slot_content) => R.bool(),
           required(:slot_content) => R.option(GuidKey.t())
         }

  @typep binding :: %{
           required(:id) => GuidKey.t(),
           required(:value) => prop_value(),
           required(:origin) => Occurrence.origin(),
           required(:rank) => R.option(R.u32()),
           required(:superseded) => R.vec(prop_value())
         }

  @doc false
  @spec items() :: [term()]
  def items do
    __rustq_type_items__() ++
      RustQ.Meta.AST.functions!(__MODULE__, [
        :empty_value,
        :component,
        :prop_value,
        :assign,
        :assignment_binding,
        :assignment_value,
        :variable_value,
        :slot_content,
        :text_characters,
        :bind,
        :bind_ref,
        :bind_field,
        :bind_symbol,
        :bind_text
      ])
  end

  @spec empty_value() :: prop_value()
  defrust empty_value() do
    struct_literal(PropValue,
      bool: nil,
      text: nil,
      guid: nil,
      has_slot_content: false,
      slot_content: nil
    )
  end

  # The defaults a component definition binds for its own expansion.
  @spec component(R.slice(R.ref(Kiwi.kiwi_record()))) :: R.vec(binding())
  defrust component(definitions) do
    definitions
    |> iter()
    |> filter_map(fn definition ->
      with {:some, id} <- guid_key(definition.record(ComponentPropDef.ID)),
           {:some, value} <- definition.record(ComponentPropDef.INITIAL_VALUE) do
        some(
          struct_literal(Binding,
            id: id,
            value: prop_value(value),
            origin: :default,
            rank: nil,
            superseded: Vec.new()
          )
        )
      else
        _ -> nil
      end
    end)
    |> collect()
  end

  # The parts of a property value or a variable value that binding reads.
  @spec prop_value(R.ref(Kiwi.kiwi_record())) :: prop_value()
  defrust prop_value(value) do
    if value.definition() == Definitions.COMPONENT_PROP_VALUE do
      %{
        empty_value()
        | bool: value.bool(ComponentPropValue.BOOL_VALUE),
          text: text_characters(value.record(ComponentPropValue.TEXT_VALUE)),
          guid: value.record(ComponentPropValue.GUID_VALUE).cloned()
      }
    else
      text =
        case value.str(VariableAnyValue.TEXT_VALUE) do
          {:some, text} -> some(text.to_string())
          :none -> text_characters(value.record(VariableAnyValue.TEXT_DATA_VALUE))
        end

      %{
        empty_value()
        | bool: value.bool(VariableAnyValue.BOOL_VALUE),
          text: text,
          has_slot_content: value.has(VariableAnyValue.SLOT_CONTENT_ID_VALUE),
          slot_content: slot_content(value)
      }
    end
  end

  @spec text_characters(R.option(R.ref(Kiwi.kiwi_record()))) :: R.option(String.t())
  defrust text_characters(text) do
    text
    |> and_then(fn text -> text.str(TextData.CHARACTERS) end)
    |> map(fn characters -> characters.to_string() end)
  end

  # The content frame a slot value names, unless it names the component's own content.
  @spec slot_content(R.ref(Kiwi.kiwi_record())) :: R.option(GuidKey.t())
  defrust slot_content(value) do
    value.record(VariableAnyValue.SLOT_CONTENT_ID_VALUE)
    |> and_then(fn slot -> guid_key(slot.record(SlotContentId.GUID)) end)
    |> filter(fn key -> deref(key) != {0xFFFFFFFF, 0xFFFFFFFF} end)
  end

  # Applies an owner's assignments over `bindings`; later entries win. A replacement keeps its
  # position and remembers the values it replaced, innermost first.
  @spec assign(R.vec(binding()), R.slice(R.ref(Kiwi.kiwi_record())), R.option(R.u32())) ::
          R.vec(binding())
  defrust assign(bindings, assignments, rank) do
    for assignment <- assignments do
      case assignment_binding(assignment, rank) do
        {:some, binding} ->
          case bindings.iter().rposition(fn previous -> previous.id == binding.id end) do
            {:some, index} ->
              previous = bindings.remove(index)
              superseded = previous.superseded
              superseded.push(previous.value)
              bindings.insert(index, %{binding | superseded: superseded})

            :none ->
              bindings.push(binding)
          end

        :none ->
          :ok
      end
    end

    bindings
  end

  @spec assignment_binding(R.ref(Kiwi.kiwi_record()), R.option(R.u32())) :: R.option(binding())
  defrust assignment_binding(assignment, rank) do
    with {:some, id} <- guid_key(assignment.record(ComponentPropAssignment.DEF_ID)),
         {:some, value} <- assignment_value(assignment) do
      some(
        struct_literal(Binding,
          id: id,
          value: value,
          origin: :assignment,
          rank: rank,
          superseded: Vec.new()
        )
      )
    else
      _ -> nil
    end
  end

  # An assignment's own value, else the component its variable value names, else the first
  # value its variable holds.
  @spec assignment_value(R.ref(Kiwi.kiwi_record())) :: R.option(prop_value())
  defrust assignment_value(assignment) do
    value = assignment.record(ComponentPropAssignment.VALUE)

    variable =
      assignment.record(ComponentPropAssignment.VAR_VALUE)
      |> and_then(fn variable -> variable.record(VariableData.VALUE) end)

    symbol =
      variable
      |> and_then(fn variable -> variable.record(VariableAnyValue.SYMBOL_ID_VALUE) end)
      |> and_then(fn symbol -> symbol.record(SymbolId.GUID) end)

    case {value, symbol, variable} do
      {{:some, value}, _symbol, _variable}
      when value.has(ComponentPropValue.BOOL_VALUE) or value.has(ComponentPropValue.TEXT_VALUE) or
             value.has(ComponentPropValue.GUID_VALUE) ->
        some(prop_value(value))

      {_value, {:some, symbol}, _variable} ->
        some(%{empty_value() | guid: some(symbol.clone())})

      {_value, _symbol, {:some, variable}} ->
        variable_value(variable)

      _ ->
        nil
    end
  end

  @spec variable_value(R.ref(Kiwi.kiwi_record())) :: R.option(prop_value())
  defrust variable_value(variable) do
    value = prop_value(variable)

    cond do
      variable.has(VariableAnyValue.BOOL_VALUE) ->
        some(%{empty_value() | bool: value.bool})

      variable.has(VariableAnyValue.TEXT_VALUE) or variable.has(VariableAnyValue.TEXT_DATA_VALUE) ->
        some(%{empty_value() | text: value.text})

      variable.has(VariableAnyValue.SLOT_CONTENT_ID_VALUE) ->
        some(%{empty_value() | has_slot_content: true, slot_content: value.slot_content})

      true ->
        nil
    end
  end

  # Binds a record's fields from the enclosing scope, with each field a binding set and the
  # binding that set it.
  @spec bind(R.ref(Kiwi.kiwi_record()), R.slice(binding())) ::
          {Kiwi.kiwi_record(), R.vec({Occurrence.binding_claim(), binding()})}
  defrust bind(record, bindings) do
    bound = record.clone()
    claims = Vec.new()

    for reference <- record.records(NodeChange.COMPONENT_PROP_REFS) do
      case bind_ref(ref(bound), reference, bindings) do
        {:some, {next, claim, binding}} ->
          assign!(bound, next)
          claims.push({claim, binding})

        :none ->
          :ok
      end
    end

    {bound, claims}
  end

  @spec bind_ref(R.ref(Kiwi.kiwi_record()), R.ref(Kiwi.kiwi_record()), R.slice(binding())) ::
          R.option({Kiwi.kiwi_record(), Occurrence.binding_claim(), binding()})
  defrust bind_ref(record, reference, bindings) do
    with false <- reference.bool(ComponentPropRef.IS_DELETED).unwrap_or(false),
         {:some, id} <- guid_key(reference.record(ComponentPropRef.DEF_ID)),
         {:some, binding} <- bindings.iter().find(fn binding -> binding.id == id end),
         {:some, {bound, field}} <- bind_field(record, reference, ref(binding.value)) do
      claim =
        struct_literal(BindingClaim, definition_id: id, field: field, origin: binding.origin)

      some({bound, claim, binding.clone()})
    else
      _ -> nil
    end
  end

  @spec bind_field(R.ref(Kiwi.kiwi_record()), R.ref(Kiwi.kiwi_record()), R.ref(prop_value())) ::
          R.option({Kiwi.kiwi_record(), Occurrence.bound_field()})
  defrust bind_field(record, reference, value) do
    case {reference.enum_value(ComponentPropRef.COMPONENT_PROP_NODE_FIELD), ref(value.bool),
          ref(value.text), ref(value.guid)} do
      {{:some, ComponentPropNodeField.VISIBLE}, {:some, visible}, _text, _guid} ->
        some({record.put_bool(NodeChange.VISIBLE, deref(visible)), :visible})

      {{:some, ComponentPropNodeField.TEXT_DATA}, _visible, {:some, text}, _guid} ->
        some({bind_text(record, text), :text_data})

      {{:some, ComponentPropNodeField.OVERRIDDEN_SYMBOL_ID}, _visible, _text, {:some, guid}} ->
        some({bind_symbol(record, guid), :symbol_data})

      # The record keeps its fields; the expansion reads the content from the binding.
      {{:some, ComponentPropNodeField.SLOT_CONTENT_ID}, _visible, _text, _guid}
      when value.has_slot_content ->
        some({record.clone(), :slot_content})

      _ ->
        nil
    end
  end

  @spec bind_symbol(R.ref(Kiwi.kiwi_record()), R.ref(Kiwi.kiwi_record())) :: Kiwi.kiwi_record()
  defrust bind_symbol(record, guid) do
    symbol_data =
      case record.record(NodeChange.SYMBOL_DATA) do
        {:some, data} -> data.clone()
        :none -> KiwiRecord.new(Definitions.SYMBOL_DATA)
      end

    record.put_record(
      NodeChange.SYMBOL_DATA,
      symbol_data.put_record(SymbolData.SYMBOL_ID, guid.clone())
    )
  end

  # New characters drop the glyphs saved for the old ones.
  @spec bind_text(R.ref(Kiwi.kiwi_record()), R.str()) :: Kiwi.kiwi_record()
  defrust bind_text(record, text) do
    text_data =
      case record.record(NodeChange.TEXT_DATA) do
        {:some, text_data} -> text_data.clone()
        :none -> KiwiRecord.new(Definitions.TEXT_DATA)
      end

    record =
      if text_data.str(TextData.CHARACTERS) != some(text),
        do: record.delete(NodeChange.DERIVED_TEXT_DATA),
        else: record.clone()

    record.put_record(NodeChange.TEXT_DATA, text_data.put_str(TextData.CHARACTERS, text))
  end
end
