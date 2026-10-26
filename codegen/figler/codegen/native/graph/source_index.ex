defmodule Figler.Codegen.Native.Graph.SourceIndex do
  @moduledoc """
  Source records by GUID, with children in saved order, for the native occurrence interpreter.

  Removed records are dropped, duplicate GUIDs are rejected, and siblings sort by their
  fractional position string, compared as text.
  """

  use RustQ.Meta,
    callable_modules: [Figler.Codegen.Native.Graph.Records, Figler.Codegen.Native.Graph.Prepare]

  alias Figler.Codegen.Native.Graph.Records
  alias KiwiCodec.RustlerGenerator.Records, as: Kiwi
  alias RustQ.Type, as: R

  @typep sources :: HashMap.t(Records.guid_key(), Kiwi.kiwi_record())
  @typep children :: HashMap.t(Records.guid_key(), R.vec(Records.guid_key()))
  @typep source_index :: %{required(:sources) => sources(), required(:children) => children()}

  # A path segment found among a record's static descendants: how many records match, and the
  # match with the direct child holding it when exactly one does.
  @typep static_segment :: %{
           required(:count) => R.usize(),
           required(:record) => R.option(Records.guid_key()),
           required(:top) => R.option(Records.guid_key())
         }

  @doc "The Rust types and functions this module defines."
  @spec items() :: [term()]
  def items, do: __rustq_items__()

  @spec source_index(R.ref(Kiwi.kiwi_record()), R.bool()) :: R.nif_result(source_index())
  defrust source_index(message, styles) do
    live = live_records(message)

    if duplicate_ids?(live) do
      {:error, badarg()}
    else
      with {:ok, prepared} <- prepare(Enum.map(live, fn record -> record.clone() end), styles) do
        {:ok,
         struct_literal(SourceIndex, sources: sources(prepared), children: children(prepared))}
      end
    end
  end

  @spec live?(R.ref(Kiwi.kiwi_record())) :: R.bool()
  defrust live?(record),
    do: record.enum_value(Kiwi.NodeChange.PHASE) != some(Kiwi.NodePhase.REMOVED)

  @spec live_records(R.ref(Kiwi.kiwi_record())) :: R.vec(R.ref(Kiwi.kiwi_record()))
  defrust live_records(message) do
    for record <- message.records(Kiwi.Message.NODE_CHANGES), live?(record), do: record
  end

  @spec duplicate_ids?(R.slice(R.ref(Kiwi.kiwi_record()))) :: R.bool()
  defrust duplicate_ids?(records) do
    ids = record_ids(records)
    length(ids) != MapSet.size(MapSet.new(ids))
  end

  @spec record_ids(R.slice(R.ref(Kiwi.kiwi_record()))) :: R.vec(Records.guid_key())
  defrust record_ids(records) do
    for record <- records, {:some, id} <- [record_id(record)], do: id
  end

  @spec sources(R.slice(Kiwi.kiwi_record())) :: sources()
  defrust sources(records) do
    for record <- records,
        {:some, id} <- [record_id(record)],
        into: %{},
        do: {id, record.clone()}
  end

  @spec children(R.slice(Kiwi.kiwi_record())) :: children()
  defrust children(records) do
    Enum.group_by(child_pairs(records), fn {parent, _id} -> parent end, fn {_parent, id} -> id end)
  end

  # Each parent and child, in the children's saved order.
  @spec child_pairs(R.slice(Kiwi.kiwi_record())) ::
          R.vec({Records.guid_key(), Records.guid_key()})
  defrust child_pairs(records) do
    ordered = Enum.sort_by(record_refs(records), &position/1)

    for record <- ordered,
        {:some, id} <- [record_id(record)],
        {:some, parent} <- [parent_id(record)],
        do: {parent, id}
  end

  @spec record_refs(R.slice(Kiwi.kiwi_record())) :: R.vec(R.ref(Kiwi.kiwi_record()))
  defrust record_refs(records), do: records |> iter() |> collect()

  @spec source(R.ref(source_index()), Records.guid_key()) :: R.option(R.ref(Kiwi.kiwi_record()))
  defrust(source(index, id), do: index.sources.get(ref(id)))

  @spec children_of(R.ref(source_index()), Records.guid_key()) :: R.slice(Records.guid_key())
  defrust children_of(index, id) do
    case index.children.get(ref(id)) do
      {:some, children} -> children.as_slice()
      :none -> ref([])
    end
  end

  # The component an instance record names.
  @spec symbol_id(R.ref(Kiwi.kiwi_record())) :: R.option(Records.guid_key())
  defrust symbol_id(record) do
    record.record(Kiwi.NodeChange.SYMBOL_DATA).and_then(fn data ->
      guid_key(data.record(Kiwi.SymbolData.SYMBOL_ID))
    end)
  end

  # A stable override key, unless it is the unset GUID layers without one share.
  @spec override_key(R.ref(Kiwi.kiwi_record())) :: R.option(Records.guid_key())
  defrust override_key(record) do
    guid_key(record.record(Kiwi.NodeChange.OVERRIDE_KEY))
    |> filter(fn key -> deref(key) != {0xFFFFFFFF, 0xFFFFFFFF} end)
  end

  # A path segment addresses a record by GUID or by its stable override key.
  @spec matches?(R.ref(Kiwi.kiwi_record()), Records.guid_key()) :: R.bool()
  defrust matches?(record, guid) do
    record_id(record) == some(guid) or override_key(record) == some(guid)
  end

  # Finds a segment among a record's static descendants, through ordinary containers but
  # never into an instance.
  @spec find_static_segment(R.ref(source_index()), Records.guid_key(), Records.guid_key()) ::
          static_segment()
  defrust find_static_segment(index, parent_id, guid) do
    found =
      Enum.reduce(children_of(index, parent_id), [], fn top, found ->
        collect_static(index, top, top, guid, found)
      end)

    case found do
      [{record, top}] ->
        struct_literal(StaticSegment, count: 1, record: some(record), top: some(top))

      found ->
        struct_literal(StaticSegment, count: length(found), record: nil, top: nil)
    end
  end

  @spec collect_static(
          R.ref(source_index()),
          Records.guid_key(),
          Records.guid_key(),
          Records.guid_key(),
          R.vec({Records.guid_key(), Records.guid_key()})
        ) :: R.vec({Records.guid_key(), Records.guid_key()})
  defrust collect_static(index, id, top, guid, found) do
    case source(index, id) do
      {:some, record} ->
        cond do
          matches?(record, guid) ->
            found ++ [{id, top}]

          symbol_id(record).is_none() ->
            Enum.reduce(children_of(index, id), found, fn child, found ->
              collect_static(index, child, top, guid, found)
            end)

          true ->
            found
        end

      :none ->
        found
    end
  end

  # Whether a path resolves in a component's own source tree, following instance links.
  @spec resolves_in_source_component?(
          R.ref(source_index()),
          Records.guid_key(),
          R.slice(Records.guid_key())
        ) ::
          R.bool()
  defrust resolves_in_source_component?(index, component_id, path) do
    resolves_from?(index, component_id, path, 0)
  end

  @spec resolves_from?(
          R.ref(source_index()),
          Records.guid_key(),
          R.slice(Records.guid_key()),
          R.usize()
        ) ::
          R.bool()
  defrust resolves_from?(index, current, path, position) do
    with {:some, segment} <- Enum.at(path, position),
         {:some, record} <- source(index, current) do
      if position == 0 and matches?(record, segment) do
        resolves_from?(index, current, path, position + 1)
      else
        case find_static_segment(index, current, segment).record do
          {:some, _found} when position + 1 == length(path) ->
            true

          {:some, found} ->
            case source(index, found).and_then(fn found -> symbol_id(found) end) do
              {:some, next} -> resolves_from?(index, next, path, position + 1)
              :none -> false
            end

          :none ->
            false
        end
      end
    else
      _ -> false
    end
  end
end
