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

  @doc "The Rust functions this module defines."
  @spec items() :: [term()]
  def items, do: __rustq_items__()

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
          Map.get(target.bound_fields, field, owner_rank) >= owner_rank,
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
            Enum.any?(text.fields(), fn {field, value} -> source.get(field) != some(value) end)

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

    if incoming == [] do
      nil
    else
      entries = dedupe_by_field(consumption_entries(base) ++ incoming)

      some(
        KiwiRecord.new(Kiwi.Definitions.VARIABLE_DATA_MAP)
        |> put_records(Kiwi.VariableDataMap.ENTRIES, entries)
      )
    end
  end

  # A record's variable consumption entries. Legacy entries precede parameter entries, which
  # may replace them per field; unkeyed entries come first, then one entry per field in
  # first-seen order.
  @spec consumption_entries(R.ref(Kiwi.kiwi_record())) :: R.vec(Kiwi.kiwi_record())
  defrust consumption_entries(record) do
    entries =
      map_entries(record, Kiwi.NodeChange.VARIABLE_CONSUMPTION_MAP) ++
        map_entries(record, Kiwi.NodeChange.PARAMETER_CONSUMPTION_MAP)

    {keyed, unkeyed} = Enum.split_with(entries, fn entry -> variable_field(entry).is_some() end)
    unkeyed ++ dedupe_by_field(keyed)
  end

  @spec map_entries(R.ref(Kiwi.kiwi_record()), R.u32()) :: R.vec(Kiwi.kiwi_record())
  defrust map_entries(record, field) do
    case record.record(field) do
      {:some, map} ->
        map.records(Kiwi.VariableDataMap.ENTRIES) |> into_iter() |> cloned() |> collect()

      :none ->
        []
    end
  end

  # Entries keep the position of a field's first entry and the value of its last.
  @spec dedupe_by_field(R.slice(Kiwi.kiwi_record())) :: R.vec(Kiwi.kiwi_record())
  defrust dedupe_by_field(entries) do
    last =
      for {entry, index} <- Enum.with_index(entries),
          {:some, field} <- [variable_field(entry)],
          into: %{},
          do: {field, index}

    # The reversed entries leave each field's first index last, to be kept.
    first =
      for {entry, index} <- entries |> Enum.with_index() |> Enum.reverse(),
          {:some, field} <- [variable_field(entry)],
          into: %{},
          do: {field, index}

    for {entry, index} <- Enum.with_index(entries),
        (case variable_field(entry) do
           {:some, field} -> first[field] == index
           :none -> true
         end) do
      case variable_field(entry) do
        {:some, field} -> entries[last[field]].clone()
        :none -> entry.clone()
      end
    end
  end

  @spec variable_field(R.ref(Kiwi.kiwi_record())) :: R.option(R.u32())
  defrust variable_field(entry), do: entry.enum_value(Kiwi.VariableDataMapEntry.VARIABLE_FIELD)
end
