defmodule Figler.Codegen.Native.Graph.SourceIndex do
  @moduledoc """
  Source records by GUID, with children in saved order, for the native occurrence interpreter.

  Mirrors `Figler.Scene.Graph.Occurrence.SourceIndex`: removed records are dropped, duplicate
  GUIDs are rejected, and siblings sort by their fractional position string, compared as text.
  """

  use RustQ.Meta,
    rust_sources: [
      "deps/kiwi_codec/codegen/kiwi_codec/rustler_generator/templates/records_runtime.rs"
    ],
    callable_modules: [Figler.Codegen.Native.Graph.Records, Figler.Codegen.Native.Graph.Prepare]

  alias RustQ.Type, as: R

  defrustmod Message, as: [:kiwi_records, :message]
  defrustmod NodeChange, as: [:kiwi_records, :node_change]
  defrustmod NodePhase, as: [:kiwi_records, :node_phase]

  @typep sources :: HashMap.t(GuidKey.t(), KiwiRecord.t())
  @typep children :: HashMap.t(GuidKey.t(), R.vec(GuidKey.t()))
  @typep source_index :: %{required(:sources) => sources(), required(:children) => children()}

  @doc false
  @spec items() :: [term()]
  def items do
    __rustq_type_items__() ++
      RustQ.Meta.AST.functions!(__MODULE__, [
        :source_index,
        :live?,
        :live_records,
        :duplicate_ids?,
        :record_ids,
        :id_set,
        :sources,
        :children,
        :child_pairs,
        :record_refs
      ])
  end

  @spec source_index(R.ref(KiwiRecord.t()), R.bool()) :: R.nif_result(source_index())
  defrust source_index(message, styles) do
    live = live_records(message)

    if duplicate_ids?(live) do
      err(badarg())
    else
      with {:ok, prepared} <- prepare(live.into_iter().cloned().collect(), styles) do
        ok(
          struct_literal(SourceIndex,
            sources: sources(prepared),
            children: children(prepared)
          )
        )
      end
    end
  end

  @spec live?(R.ref(KiwiRecord.t())) :: R.bool()
  defrust live?(record), do: record.enum_value(NodeChange.PHASE) != some(NodePhase.REMOVED)

  @spec live_records(R.ref(KiwiRecord.t())) :: R.vec(R.ref(KiwiRecord.t()))
  defrust live_records(message) do
    for record <- message.records(Message.NODE_CHANGES), live?(record), do: record
  end

  @spec duplicate_ids?(R.slice(R.ref(KiwiRecord.t()))) :: R.bool()
  defrust duplicate_ids?(records) do
    ids = record_ids(records)
    ids.len() != id_set(ref(ids)).len()
  end

  @spec record_ids(R.slice(R.ref(KiwiRecord.t()))) :: R.vec(GuidKey.t())
  defrust record_ids(records) do
    records |> iter() |> filter_map(fn record -> record_id(record) end) |> collect()
  end

  @spec id_set(R.slice(GuidKey.t())) :: HashSet.t(GuidKey.t())
  defrust id_set(ids), do: ids |> iter() |> copied() |> collect()

  @spec sources(R.slice(KiwiRecord.t())) :: sources()
  defrust sources(records) do
    records
    |> iter()
    |> filter_map(fn record -> record_id(record).map(fn id -> {id, record.clone()} end) end)
    |> collect()
  end

  @spec children(R.slice(KiwiRecord.t())) :: children()
  defrust children(records) do
    children = HashMap.new()

    for {parent, id} <- child_pairs(records) do
      children.entry(parent).or_default().push(id)
    end

    children
  end

  # Each parent and child, in the children's saved order.
  @spec child_pairs(R.slice(KiwiRecord.t())) :: R.vec({GuidKey.t(), GuidKey.t()})
  defrust child_pairs(records) do
    ordered = record_refs(records)
    ordered.sort_by_key(fn record -> position(record) end)

    ordered
    |> iter()
    |> filter_map(fn record ->
      with {:some, id} <- record_id(record),
           {:some, parent} <- parent_id(record) do
        some({parent, id})
      else
        _ -> nil
      end
    end)
    |> collect()
  end

  @spec record_refs(R.slice(KiwiRecord.t())) :: R.vec(R.ref(KiwiRecord.t()))
  defrust record_refs(records), do: records |> iter() |> collect()
end
