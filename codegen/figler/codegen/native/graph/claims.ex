defmodule Figler.Codegen.Native.Graph.Claims do
  @moduledoc """
  Applies property values onto an occurrence's effective record, for the native interpreter.

  Ported from OpenPencil's `instance-overrides`, with its field lists.
  """

  use RustQ.Meta,
    callable_modules: [Figler.Codegen.Native.Graph.Occurrence]

  alias Figler.Codegen.Native.Graph.Occurrence
  alias KiwiCodec.RustlerGenerator.Records, as: Kiwi
  alias RustQ.Type, as: R

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
      Kiwi.NodeChange.COMPONENT_KEY,
      Kiwi.NodeChange.SOURCE_LIBRARY_KEY,
      Kiwi.NodeChange.PUBLISH_ID,
      Kiwi.NodeChange.PUBLISHED_VERSION,
      Kiwi.NodeChange.SHARED_SYMBOL_VERSION,
      Kiwi.NodeChange.IS_SYMBOL_PUBLISHABLE,
      Kiwi.NodeChange.VARIANT_PROP_SPECS,
      Kiwi.NodeChange.COMPONENT_PROP_DEFS,
      Kiwi.NodeChange.OVERRIDE_KEY
    ])
  end

  # Fields whose change invalidates saved glyphs unless the claim supplies new ones.
  @spec text_shaping() :: R.slice(R.u32(), R.lifetime(:static))
  defrust text_shaping() do
    ref([
      Kiwi.NodeChange.FONT_SIZE,
      Kiwi.NodeChange.FONT_NAME,
      Kiwi.NodeChange.FONT_VARIATIONS,
      Kiwi.NodeChange.LETTER_SPACING,
      Kiwi.NodeChange.LINE_HEIGHT,
      Kiwi.NodeChange.TEXT_CASE,
      Kiwi.NodeChange.TEXT_ALIGN_HORIZONTAL,
      Kiwi.NodeChange.TEXT_ALIGN_VERTICAL,
      Kiwi.NodeChange.TEXT_AUTO_RESIZE,
      Kiwi.NodeChange.STYLE_ID_FOR_TEXT,
      Kiwi.NodeChange.FONT_VARIANT_COMMON_LIGATURES,
      Kiwi.NodeChange.FONT_VARIANT_CONTEXTUAL_LIGATURES
    ])
  end

  # The fields of a claim its owner keeps on `target`: an outer owner's assignment, recorded
  # with a strictly smaller rank, supersedes the claim.
  @spec retained(R.ref(Kiwi.kiwi_record()), R.ref(Occurrence.occurrence()), R.u32()) ::
          Kiwi.kiwi_record()
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
  @spec apply_claim(R.mut_ref(Occurrence.occurrence()), R.ref(Kiwi.kiwi_record())) :: R.unit()
  defrust apply_claim(target, props) do
    merged = invalidate_inherited_text(ref(target.properties), props).merge(props)

    properties =
      case merge_variable_consumption(ref(target.properties), props) do
        {:some, consumption} ->
          merged.put_record(Kiwi.NodeChange.PARAMETER_CONSUMPTION_MAP, consumption)

        :none ->
          merged
      end

    assign!(target.properties, properties)
    assign!(target.has_own_name, target.has_own_name or props.has(Kiwi.NodeChange.NAME))
    target.overridden.extend(props.field_ids())
  end

  # Drops saved glyphs when a claim changes text or shaping and supplies none.
  @spec invalidate_inherited_text(R.ref(Kiwi.kiwi_record()), R.ref(Kiwi.kiwi_record())) ::
          Kiwi.kiwi_record()
  defrust invalidate_inherited_text(properties, patch) do
    if not patch.has(Kiwi.NodeChange.DERIVED_TEXT_DATA) and
         (changed_text?(properties, patch) or changed_shaping?(properties, patch)) do
      properties.delete(Kiwi.NodeChange.DERIVED_TEXT_DATA)
    else
      properties.clone()
    end
  end

  @spec changed_text?(R.ref(Kiwi.kiwi_record()), R.ref(Kiwi.kiwi_record())) :: R.bool()
  defrust changed_text?(properties, patch) do
    case patch.record(Kiwi.NodeChange.TEXT_DATA) do
      {:some, text} ->
        case properties.record(Kiwi.NodeChange.TEXT_DATA) do
          {:some, source} ->
            text.fields().any(fn {field, value} -> source.get(field) != some(value) end)

          :none ->
            true
        end

      :none ->
        false
    end
  end

  @spec changed_shaping?(R.ref(Kiwi.kiwi_record()), R.ref(Kiwi.kiwi_record())) :: R.bool()
  defrust changed_shaping?(properties, patch) do
    Enum.any?(text_shaping(), fn field ->
      patch.has(deref(field)) and properties.get(deref(field)) != patch.get(deref(field))
    end)
  end

  # Merges variable consumption entries, later entries replacing earlier ones for the same
  # field. The result is written as the parameter map, which readers consult after the legacy
  # map.
  @spec merge_variable_consumption(R.ref(Kiwi.kiwi_record()), R.ref(Kiwi.kiwi_record())) ::
          R.option(Kiwi.kiwi_record())
  defrust merge_variable_consumption(base, patch) do
    incoming = consumption_entries(patch)

    if incoming.is_empty() do
      nil
    else
      entries = consumption_entries(base)
      entries.extend(incoming)

      some(
        KiwiRecord.new(Kiwi.Definitions.VARIABLE_DATA_MAP)
        |> put_records(Kiwi.VariableDataMap.ENTRIES, dedupe_by_field(entries))
      )
    end
  end

  # A record's variable consumption entries. Legacy entries precede parameter entries, which
  # may replace them per field; unkeyed entries come first, then one entry per field in
  # first-seen order.
  @spec consumption_entries(R.ref(Kiwi.kiwi_record())) :: R.vec(Kiwi.kiwi_record())
  defrust consumption_entries(record) do
    entries = map_entries(record, Kiwi.NodeChange.VARIABLE_CONSUMPTION_MAP)
    entries.extend(map_entries(record, Kiwi.NodeChange.PARAMETER_CONSUMPTION_MAP))

    unkeyed =
      for entry <- entries.iter(),
          entry.enum_value(Kiwi.VariableDataMapEntry.VARIABLE_FIELD).is_none(),
          do: entry.clone()

    keyed =
      for entry <- entries.iter(),
          entry.enum_value(Kiwi.VariableDataMapEntry.VARIABLE_FIELD).is_some(),
          do: entry.clone()

    unkeyed.extend(dedupe_by_field(keyed))
    unkeyed
  end

  @spec map_entries(R.ref(Kiwi.kiwi_record()), R.u32()) :: R.vec(Kiwi.kiwi_record())
  defrust map_entries(record, field) do
    case record.record(field) do
      {:some, map} ->
        map.records(Kiwi.VariableDataMap.ENTRIES) |> into_iter() |> cloned() |> collect()

      :none ->
        Vec.new()
    end
  end

  # Entries keep the position of a field's first entry and the value of its last.
  @spec dedupe_by_field(R.slice(Kiwi.kiwi_record())) :: R.vec(Kiwi.kiwi_record())
  defrust dedupe_by_field(entries) do
    last = HashMap.new()

    for {entry, index} <- Enum.with_index(entries) do
      case entry.enum_value(Kiwi.VariableDataMapEntry.VARIABLE_FIELD) do
        {:some, field} -> last.insert(field, index)
        :none -> nil
      end
    end

    seen = HashSet.new()
    kept = Vec.new()

    for entry <- entries do
      case entry.enum_value(Kiwi.VariableDataMapEntry.VARIABLE_FIELD) do
        {:some, field} ->
          if seen.insert(field), do: kept.push(entries[last[ref(field)]].clone())

        :none ->
          kept.push(entry.clone())
      end
    end

    kept
  end
end
