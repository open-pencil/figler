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
  alias Figler.Codegen.Native.Graph.Records
  alias KiwiCodec.RustlerGenerator.Records, as: Kiwi
  alias RustQ.Type, as: R

  @typep prop_value :: %{
           required(:bool) => R.option(R.bool()),
           required(:text) => R.option(String.t()),
           required(:guid) => R.option(Kiwi.kiwi_record()),
           required(:has_slot_content) => R.bool(),
           required(:slot_content) => R.option(Records.guid_key())
         }

  @typep binding :: %{
           required(:id) => Records.guid_key(),
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
    for definition <- definitions,
        {:some, id} <- [guid_key(definition.record(Kiwi.ComponentPropDef.ID))],
        {:some, value} <- [definition.record(Kiwi.ComponentPropDef.INITIAL_VALUE)] do
      struct_literal(Binding,
        id: id,
        value: prop_value(value),
        origin: :default,
        rank: nil,
        superseded: Vec.new()
      )
    end
  end

  # The parts of a property value or a variable value that binding reads.
  @spec prop_value(R.ref(Kiwi.kiwi_record())) :: prop_value()
  defrust prop_value(value) do
    if value.definition() == Kiwi.Definitions.COMPONENT_PROP_VALUE do
      %{
        empty_value()
        | bool: value.bool(Kiwi.ComponentPropValue.BOOL_VALUE),
          text: text_characters(value.record(Kiwi.ComponentPropValue.TEXT_VALUE)),
          guid: value.record(Kiwi.ComponentPropValue.GUID_VALUE).cloned()
      }
    else
      text =
        case value.str(Kiwi.VariableAnyValue.TEXT_VALUE) do
          {:some, text} -> some(text.to_string())
          :none -> text_characters(value.record(Kiwi.VariableAnyValue.TEXT_DATA_VALUE))
        end

      %{
        empty_value()
        | bool: value.bool(Kiwi.VariableAnyValue.BOOL_VALUE),
          text: text,
          has_slot_content: value.has(Kiwi.VariableAnyValue.SLOT_CONTENT_ID_VALUE),
          slot_content: slot_content(value)
      }
    end
  end

  @spec text_characters(R.option(R.ref(Kiwi.kiwi_record()))) :: R.option(String.t())
  defrust text_characters(text) do
    text
    |> and_then(fn text -> text.str(Kiwi.TextData.CHARACTERS) end)
    |> map(fn characters -> characters.to_string() end)
  end

  # The content frame a slot value names, unless it names the component's own content.
  @spec slot_content(R.ref(Kiwi.kiwi_record())) :: R.option(Records.guid_key())
  defrust slot_content(value) do
    value.record(Kiwi.VariableAnyValue.SLOT_CONTENT_ID_VALUE)
    |> and_then(fn slot -> guid_key(slot.record(Kiwi.SlotContentId.GUID)) end)
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
    with {:some, id} <- guid_key(assignment.record(Kiwi.ComponentPropAssignment.DEF_ID)),
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
    value = assignment.record(Kiwi.ComponentPropAssignment.VALUE)

    variable =
      assignment.record(Kiwi.ComponentPropAssignment.VAR_VALUE)
      |> and_then(fn variable -> variable.record(Kiwi.VariableData.VALUE) end)

    symbol =
      variable
      |> and_then(fn variable -> variable.record(Kiwi.VariableAnyValue.SYMBOL_ID_VALUE) end)
      |> and_then(fn symbol -> symbol.record(Kiwi.SymbolId.GUID) end)

    case {value, symbol, variable} do
      {{:some, value}, _symbol, _variable}
      when value.has(Kiwi.ComponentPropValue.BOOL_VALUE) or
             value.has(Kiwi.ComponentPropValue.TEXT_VALUE) or
             value.has(Kiwi.ComponentPropValue.GUID_VALUE) ->
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
      variable.has(Kiwi.VariableAnyValue.BOOL_VALUE) ->
        some(%{empty_value() | bool: value.bool})

      variable.has(Kiwi.VariableAnyValue.TEXT_VALUE) or
          variable.has(Kiwi.VariableAnyValue.TEXT_DATA_VALUE) ->
        some(%{empty_value() | text: value.text})

      variable.has(Kiwi.VariableAnyValue.SLOT_CONTENT_ID_VALUE) ->
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

    for reference <- record.records(Kiwi.NodeChange.COMPONENT_PROP_REFS) do
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
    with false <- reference.bool(Kiwi.ComponentPropRef.IS_DELETED).unwrap_or(false),
         {:some, id} <- guid_key(reference.record(Kiwi.ComponentPropRef.DEF_ID)),
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
    case {reference.enum_value(Kiwi.ComponentPropRef.COMPONENT_PROP_NODE_FIELD), ref(value.bool),
          ref(value.text), ref(value.guid)} do
      {{:some, Kiwi.ComponentPropNodeField.VISIBLE}, {:some, visible}, _text, _guid} ->
        some({record.put_bool(Kiwi.NodeChange.VISIBLE, deref(visible)), :visible})

      {{:some, Kiwi.ComponentPropNodeField.TEXT_DATA}, _visible, {:some, text}, _guid} ->
        some({bind_text(record, text), :text_data})

      {{:some, Kiwi.ComponentPropNodeField.OVERRIDDEN_SYMBOL_ID}, _visible, _text, {:some, guid}} ->
        some({bind_symbol(record, guid), :symbol_data})

      # The record keeps its fields; the expansion reads the content from the binding.
      {{:some, Kiwi.ComponentPropNodeField.SLOT_CONTENT_ID}, _visible, _text, _guid}
      when value.has_slot_content ->
        some({record.clone(), :slot_content})

      _ ->
        nil
    end
  end

  @spec bind_symbol(R.ref(Kiwi.kiwi_record()), R.ref(Kiwi.kiwi_record())) :: Kiwi.kiwi_record()
  defrust bind_symbol(record, guid) do
    symbol_data =
      case record.record(Kiwi.NodeChange.SYMBOL_DATA) do
        {:some, data} -> data.clone()
        :none -> KiwiRecord.new(Kiwi.Definitions.SYMBOL_DATA)
      end

    record.put_record(
      Kiwi.NodeChange.SYMBOL_DATA,
      symbol_data.put_record(Kiwi.SymbolData.SYMBOL_ID, guid.clone())
    )
  end

  # New characters drop the glyphs saved for the old ones.
  @spec bind_text(R.ref(Kiwi.kiwi_record()), R.str()) :: Kiwi.kiwi_record()
  defrust bind_text(record, text) do
    text_data =
      case record.record(Kiwi.NodeChange.TEXT_DATA) do
        {:some, text_data} -> text_data.clone()
        :none -> KiwiRecord.new(Kiwi.Definitions.TEXT_DATA)
      end

    record =
      if text_data.str(Kiwi.TextData.CHARACTERS) != some(text),
        do: record.delete(Kiwi.NodeChange.DERIVED_TEXT_DATA),
        else: record.clone()

    record.put_record(
      Kiwi.NodeChange.TEXT_DATA,
      text_data.put_str(Kiwi.TextData.CHARACTERS, text)
    )
  end
end
