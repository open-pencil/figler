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
  defrustmod Guid, as: [:kiwi_records, :guid]
  defrustmod ParentIndex, as: [:kiwi_records, :parent_index]
  defrustmod NodePhase, as: [:kiwi_records, :node_phase]

  @type guid_key :: {R.u32(), R.u32()}

  @type sources :: HashMap.t(guid_key(), KiwiRecord.t())
  @type children :: HashMap.t(guid_key(), R.vec(guid_key()))

  @type source_index :: %{required(:sources) => sources(), required(:children) => children()}

  @doc false
  @spec items() :: [term()]
  def items do
    # The index never crosses the NIF boundary, so its types need no term decoders.
    Enum.reject(__rustq_type_items__(), &match?(%RustQ.Rust.AST.Function{}, &1)) ++
      RustQ.Meta.AST.functions!(__MODULE__, [
        :guid_key,
        :record_id,
        :parent_id,
        :position,
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
        :push_child
      ])
  end

  @spec guid_key(R.option(R.ref(R.path(:KiwiRecord)))) :: R.option(guid_key())
  defrust guid_key(guid) do
    with {:some, guid} <- guid,
         {:some, session} <- guid.uint(Guid.SESSION_ID),
         {:some, local} <- guid.uint(Guid.LOCAL_ID) do
      some({session, local})
    else
      _ -> nil
    end
  end

  @spec record_id(R.ref(R.path(:KiwiRecord))) :: R.option(guid_key())
  defrust record_id(record), do: guid_key(record.record(NodeChange.GUID))

  @spec parent_id(R.ref(R.path(:KiwiRecord))) :: R.option(guid_key())
  defrust parent_id(record) do
    case record.record(NodeChange.PARENT_INDEX) do
      {:some, parent} -> guid_key(parent.record(ParentIndex.GUID))
      :none -> nil
    end
  end

  # Saved sibling order: the fractional position string, compared as text.
  @spec position(R.ref(R.path(:KiwiRecord))) :: R.str()
  defrust position(record) do
    case record.record(NodeChange.PARENT_INDEX) do
      {:some, parent} -> parent.str(ParentIndex.POSITION).unwrap_or("")
      :none -> ""
    end
  end

  @spec live_record(R.ref(R.path(:KiwiRecord))) :: R.bool()
  defrust live_record(record), do: record.enum_value(NodeChange.PHASE) != some(NodePhase.REMOVED)

  @spec source_index(R.ref(R.path(:KiwiRecord))) :: R.nif_result(source_index())
  defrust source_index(message) do
    live = live_records(message)

    if duplicate_ids(live) do
      err(badarg())
    else
      ok(struct_literal(SourceIndex, sources: sources(live), children: children(live)))
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

  @spec record_ids(R.slice(R.ref(R.path(:KiwiRecord)))) :: R.vec(guid_key())
  defrust record_ids(records) do
    records |> iter() |> filter_map(fn record -> record_id(record) end) |> collect()
  end

  @spec id_set(R.slice(guid_key())) :: HashSet.t(guid_key())
  defrust id_set(ids), do: ids |> iter() |> copied() |> collect()

  @spec sources(R.slice(R.ref(R.path(:KiwiRecord)))) :: sources()
  defrust sources(records) do
    records
    |> iter()
    |> filter_map(fn record ->
      record_id(record).map(fn id -> {id, deref(record).clone()} end)
    end)
    |> collect()
  end

  @spec children(R.slice(R.ref(R.path(:KiwiRecord)))) :: children()
  defrust children(records) do
    children = no_children()

    for {parent, id} <- child_pairs(records) do
      push_child(mut_ref(children), parent, id)
    end

    children
  end

  @spec push_child(R.mut_ref(children()), guid_key(), guid_key()) :: R.unit()
  defrust push_child(children, parent, id), do: children.entry(parent).or_default().push(id)

  @spec no_children() :: children()
  defrust no_children(), do: HashMap.new()

  # Each parent and child, in the children's saved order.
  @spec child_pairs(R.slice(R.ref(R.path(:KiwiRecord)))) :: R.vec({guid_key(), guid_key()})
  defrust child_pairs(records) do
    ordered = records.to_vec()
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
