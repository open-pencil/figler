defmodule Figler.Codegen.Native.Graph.Claims do
  @moduledoc """
  Applies property values onto an occurrence's effective record, for the native interpreter.

  Mirrors `Figler.Scene.Graph.Occurrence.Claims` and the field lists of
  `Figler.Scene.Graph.Occurrence.Fields`.
  """

  use RustQ.Meta,
    rust_sources: [
      "deps/kiwi_codec/codegen/kiwi_codec/rustler_generator/templates/records_runtime.rs"
    ],
    callable_modules: [Figler.Codegen.Native.Graph.Occurrence]

  alias Figler.Codegen.Native.Graph.Occurrence
  alias RustQ.Type, as: R

  defrustmod NodeChange, as: [:kiwi_records, :node_change]
  defrustmod VariableDataMap, as: [:kiwi_records, :variable_data_map]
  defrustmod VariableDataMapEntry, as: [:kiwi_records, :variable_data_map_entry]
  defrustmod Definitions, as: [:kiwi_record_definitions]

  @doc false
  @spec items() :: [term()]
  def items do
    RustQ.Meta.AST.functions!(__MODULE__, [
      :component_identity,
      :text_shaping,
      :retained,
      :apply_claim,
      :invalidate_inherited_text,
      :changed_text?,
      :changed_shaping?,
      :merge_variable_consumption,
      :consumption_entries,
      :map_entries,
      :dedupe_by_field
    ])
  end

  # A component's own identity, which an instance does not take from it.
  @spec component_identity() :: R.slice(R.u32(), R.lifetime(:static))
  defrust component_identity() do
    ref([
      NodeChange.COMPONENT_KEY,
      NodeChange.SOURCE_LIBRARY_KEY,
      NodeChange.PUBLISH_ID,
      NodeChange.PUBLISHED_VERSION,
      NodeChange.SHARED_SYMBOL_VERSION,
      NodeChange.IS_SYMBOL_PUBLISHABLE,
      NodeChange.VARIANT_PROP_SPECS,
      NodeChange.COMPONENT_PROP_DEFS,
      NodeChange.OVERRIDE_KEY
    ])
  end

  # Fields whose change invalidates saved glyphs unless the claim supplies new ones.
  @spec text_shaping() :: R.slice(R.u32(), R.lifetime(:static))
  defrust text_shaping() do
    ref([
      NodeChange.FONT_SIZE,
      NodeChange.FONT_NAME,
      NodeChange.FONT_VARIATIONS,
      NodeChange.LETTER_SPACING,
      NodeChange.LINE_HEIGHT,
      NodeChange.TEXT_CASE,
      NodeChange.TEXT_ALIGN_HORIZONTAL,
      NodeChange.TEXT_ALIGN_VERTICAL,
      NodeChange.TEXT_AUTO_RESIZE,
      NodeChange.STYLE_ID_FOR_TEXT,
      NodeChange.FONT_VARIANT_COMMON_LIGATURES,
      NodeChange.FONT_VARIANT_CONTEXTUAL_LIGATURES
    ])
  end

  # The fields of a claim its owner keeps on `target`: an outer owner's assignment, recorded
  # with a strictly smaller rank, supersedes the claim.
  @spec retained(R.ref(KiwiRecord.t()), R.ref(Occurrence.occurrence()), R.u32()) :: KiwiRecord.t()
  defrust retained(props, target, owner_rank) do
    kept =
      for field <- props.field_ids(),
          target.bound_fields.get(ref(field)).is_none_or(fn rank ->
            deref(rank) >= owner_rank
          end),
          do: field

    props.take(kept)
  end

  # Merges claimed fields into an occurrence's effective record.
  @spec apply_claim(R.mut_ref(Occurrence.occurrence()), R.ref(KiwiRecord.t())) :: R.unit()
  defrust apply_claim(target, props) do
    merged = invalidate_inherited_text(ref(target.properties), props).merge(props)

    properties =
      case merge_variable_consumption(ref(target.properties), props) do
        {:some, consumption} ->
          merged.put_record(NodeChange.PARAMETER_CONSUMPTION_MAP, consumption)

        :none ->
          merged
      end

    assign!(target.properties, properties)
    assign!(target.has_own_name, target.has_own_name or props.has(NodeChange.NAME))
    target.overridden.extend(props.field_ids())
  end

  # Drops saved glyphs when a claim changes text or shaping and supplies none.
  @spec invalidate_inherited_text(R.ref(KiwiRecord.t()), R.ref(KiwiRecord.t())) :: KiwiRecord.t()
  defrust invalidate_inherited_text(properties, patch) do
    if not patch.has(NodeChange.DERIVED_TEXT_DATA) and
         (changed_text?(properties, patch) or changed_shaping?(properties, patch)) do
      properties.delete(NodeChange.DERIVED_TEXT_DATA)
    else
      properties.clone()
    end
  end

  @spec changed_text?(R.ref(KiwiRecord.t()), R.ref(KiwiRecord.t())) :: R.bool()
  defrust changed_text?(properties, patch) do
    case patch.record(NodeChange.TEXT_DATA) do
      {:some, text} ->
        case properties.record(NodeChange.TEXT_DATA) do
          {:some, source} ->
            text.fields().any(fn {field, value} -> source.get(field) != some(value) end)

          :none ->
            true
        end

      :none ->
        false
    end
  end

  @spec changed_shaping?(R.ref(KiwiRecord.t()), R.ref(KiwiRecord.t())) :: R.bool()
  defrust changed_shaping?(properties, patch) do
    text_shaping()
    |> iter()
    |> any(fn field ->
      patch.has(deref(field)) and properties.get(deref(field)) != patch.get(deref(field))
    end)
  end

  # Merges variable consumption entries, later entries replacing earlier ones for the same
  # field. The result is written as the parameter map, which readers consult after the legacy
  # map.
  @spec merge_variable_consumption(R.ref(KiwiRecord.t()), R.ref(KiwiRecord.t())) ::
          R.option(KiwiRecord.t())
  defrust merge_variable_consumption(base, patch) do
    incoming = consumption_entries(patch)

    if incoming.is_empty() do
      nil
    else
      entries = consumption_entries(base)
      entries.extend(incoming)

      some(
        KiwiRecord.new(Definitions.VARIABLE_DATA_MAP)
        |> put_records(VariableDataMap.ENTRIES, dedupe_by_field(entries))
      )
    end
  end

  # A record's variable consumption entries. Legacy entries precede parameter entries, which
  # may replace them per field; unkeyed entries come first, then one entry per field in
  # first-seen order.
  @spec consumption_entries(R.ref(KiwiRecord.t())) :: R.vec(KiwiRecord.t())
  defrust consumption_entries(record) do
    entries = map_entries(record, NodeChange.VARIABLE_CONSUMPTION_MAP)
    entries.extend(map_entries(record, NodeChange.PARAMETER_CONSUMPTION_MAP))

    unkeyed =
      for entry <- entries.iter(),
          entry.enum_value(VariableDataMapEntry.VARIABLE_FIELD).is_none(),
          do: entry.clone()

    keyed =
      for entry <- entries.iter(),
          entry.enum_value(VariableDataMapEntry.VARIABLE_FIELD).is_some(),
          do: entry.clone()

    unkeyed.extend(dedupe_by_field(keyed))
    unkeyed
  end

  @spec map_entries(R.ref(KiwiRecord.t()), R.u32()) :: R.vec(KiwiRecord.t())
  defrust map_entries(record, field) do
    case record.record(field) do
      {:some, map} -> map.records(VariableDataMap.ENTRIES) |> into_iter() |> cloned() |> collect()
      :none -> Vec.new()
    end
  end

  # Entries keep the position of a field's first entry and the value of its last.
  @spec dedupe_by_field(R.slice(KiwiRecord.t())) :: R.vec(KiwiRecord.t())
  defrust dedupe_by_field(entries) do
    last = HashMap.new()

    for {index, entry} <- entries.iter().enumerate() do
      case entry.enum_value(VariableDataMapEntry.VARIABLE_FIELD) do
        {:some, field} -> last.insert(field, index)
        :none -> nil
      end
    end

    seen = HashSet.new()
    kept = Vec.new()

    for entry <- entries do
      case entry.enum_value(VariableDataMapEntry.VARIABLE_FIELD) do
        {:some, field} ->
          if seen.insert(field), do: kept.push(entries[last[ref(field)]].clone())

        :none ->
          kept.push(entry.clone())
      end
    end

    kept
  end
end
