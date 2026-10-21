defmodule Figler.Codegen.Native.Graph.SourceIndex do
  @moduledoc """
  Source records by GUID, with children in saved order, for the native occurrence interpreter.

  Mirrors `Figler.Scene.Graph.Occurrence.SourceIndex`: removed records are dropped, duplicate
  GUIDs are rejected, and siblings sort by their fractional position string, compared as text.
  """

  use RustQ.Meta,
    rust_sources: [
      "deps/kiwi_codec/codegen/kiwi_codec/rustler_generator/templates/records_runtime.rs"
    ]

  alias RustQ.Type, as: R

  defrustmod Message, as: [:kiwi_records, :message]
  defrustmod NodeChange, as: [:kiwi_records, :node_change]
  defrustmod NodePhase, as: [:kiwi_records, :node_phase]

  @type sources :: HashMap.t(GuidKey.t(), KiwiRecord.t())
  @type children :: HashMap.t(GuidKey.t(), R.vec(GuidKey.t()))

  @type source_index :: %{required(:sources) => sources(), required(:children) => children()}

  @doc false
  @spec items() :: [term()]
  def items do
    # The index never crosses the NIF boundary, so its types need no term decoders.
    Enum.reject(__rustq_type_items__(), &match?(%RustQ.Rust.AST.Function{}, &1)) ++
      RustQ.Meta.AST.functions!(__MODULE__, [
        :live_record,
        :source_index,
        :duplicate_ids,
        :sources,
        :children,
        :live_records,
        :record_ids,
        :id_set,
        :no_children,
        :child_pairs,
        :push_child,
        :record_refs
      ])
  end

  @spec live_record(R.ref(R.path(:KiwiRecord))) :: R.bool()
  defrust live_record(record), do: not enum_is(record, NodeChange.PHASE, NodePhase.REMOVED)

  @spec source_index(R.ref(KiwiRecord.t()), R.bool()) :: R.nif_result(source_index())
  defrust source_index(message, styles) do
    live = live_records(message)

    if duplicate_ids(ref(live)) do
      err(badarg())
    else
      case prepare(live.into_iter().cloned().collect(), styles) do
        {:ok, prepared} ->
          ok(
            struct_literal(SourceIndex,
              sources: sources(ref(prepared)),
              children: children(ref(prepared))
            )
          )

        {:error, error} ->
          err(error)
      end
    end
  end

  @spec live_records(R.ref(R.path(:KiwiRecord))) :: R.vec(R.ref(R.path(:KiwiRecord)))
  defrust live_records(message) do
    message
    |> records(Message.NODE_CHANGES)
    |> into_iter()
    |> filter(fn record -> live_record(record) end)
    |> collect()
  end

  @spec duplicate_ids(R.slice(R.ref(R.path(:KiwiRecord)))) :: R.bool()
  defrust duplicate_ids(records) do
    ids = record_ids(records)
    ids.len() != id_set(ids).len()
  end

  @spec record_ids(R.slice(R.ref(R.path(:KiwiRecord)))) :: R.vec(GuidKey.t())
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
    children = no_children()

    for {parent, id} <- child_pairs(records) do
      push_child(mut_ref(children), parent, id)
    end

    children
  end

  @spec push_child(R.mut_ref(children()), GuidKey.t(), GuidKey.t()) :: R.unit()
  defrust push_child(children, parent, id), do: children.entry(parent).or_default().push(id)

  @spec record_refs(R.slice(KiwiRecord.t())) :: R.vec(R.ref(KiwiRecord.t()))
  defrust record_refs(records), do: records |> iter() |> collect()

  @spec no_children() :: children()
  defrust no_children(), do: HashMap.new()

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
end
