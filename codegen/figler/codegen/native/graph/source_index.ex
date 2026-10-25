defmodule Figler.Codegen.Native.Graph.SourceIndex do
  @moduledoc """
  Source records by GUID, with children in saved order, for the native occurrence interpreter.

  Removed records are dropped, duplicate GUIDs are rejected, and siblings sort by their
  fractional position string, compared as text.
  """

  use RustQ.Meta,
    callable_modules: [Figler.Codegen.Native.Graph.Records, Figler.Codegen.Native.Graph.Prepare]

  alias KiwiCodec.RustlerGenerator.Records, as: Kiwi
  alias RustQ.Type, as: R

  @typep sources :: HashMap.t(GuidKey.t(), Kiwi.kiwi_record())
  @typep children :: HashMap.t(GuidKey.t(), R.vec(GuidKey.t()))
  @typep source_index :: %{required(:sources) => sources(), required(:children) => children()}

  # A path segment found among a record's static descendants: how many records match, and the
  # match with the direct child holding it when exactly one does.
  @typep static_segment :: %{
           required(:count) => R.usize(),
           required(:record) => R.option(GuidKey.t()),
           required(:top) => R.option(GuidKey.t())
         }

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
        :record_refs,
        :source,
        :children_of,
        :symbol_id,
        :override_key,
        :matches?,
        :find_static_segment,
        :collect_static,
        :resolves_in_source_component?,
        :resolves_from?
      ])
  end

  @spec source_index(R.ref(Kiwi.kiwi_record()), R.bool()) :: R.nif_result(source_index())
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
    ids.len() != id_set(ref(ids)).len()
  end

  @spec record_ids(R.slice(R.ref(Kiwi.kiwi_record()))) :: R.vec(GuidKey.t())
  defrust record_ids(records) do
    records |> iter() |> filter_map(fn record -> record_id(record) end) |> collect()
  end

  @spec id_set(R.slice(GuidKey.t())) :: HashSet.t(GuidKey.t())
  defrust id_set(ids), do: ids |> iter() |> copied() |> collect()

  @spec sources(R.slice(Kiwi.kiwi_record())) :: sources()
  defrust sources(records) do
    records
    |> iter()
    |> filter_map(fn record -> record_id(record).map(fn id -> {id, record.clone()} end) end)
    |> collect()
  end

  @spec children(R.slice(Kiwi.kiwi_record())) :: children()
  defrust children(records) do
    children = HashMap.new()

    for {parent, id} <- child_pairs(records) do
      children.entry(parent).or_default().push(id)
    end

    children
  end

  # Each parent and child, in the children's saved order.
  @spec child_pairs(R.slice(Kiwi.kiwi_record())) :: R.vec({GuidKey.t(), GuidKey.t()})
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

  @spec record_refs(R.slice(Kiwi.kiwi_record())) :: R.vec(R.ref(Kiwi.kiwi_record()))
  defrust record_refs(records), do: records |> iter() |> collect()

  @spec source(R.ref(source_index()), GuidKey.t()) :: R.option(R.ref(Kiwi.kiwi_record()))
  defrust(source(index, id), do: index.sources.get(ref(id)))

  @spec children_of(R.ref(source_index()), GuidKey.t()) :: R.slice(GuidKey.t())
  defrust children_of(index, id) do
    case index.children.get(ref(id)) do
      {:some, children} -> children.as_slice()
      :none -> ref([])
    end
  end

  # The component an instance record names.
  @spec symbol_id(R.ref(Kiwi.kiwi_record())) :: R.option(GuidKey.t())
  defrust symbol_id(record) do
    record.record(Kiwi.NodeChange.SYMBOL_DATA).and_then(fn data ->
      guid_key(data.record(Kiwi.SymbolData.SYMBOL_ID))
    end)
  end

  # A stable override key, unless it is the unset GUID layers without one share.
  @spec override_key(R.ref(Kiwi.kiwi_record())) :: R.option(GuidKey.t())
  defrust override_key(record) do
    guid_key(record.record(Kiwi.NodeChange.OVERRIDE_KEY))
    |> filter(fn key -> deref(key) != {0xFFFFFFFF, 0xFFFFFFFF} end)
  end

  # A path segment addresses a record by GUID or by its stable override key.
  @spec matches?(R.ref(Kiwi.kiwi_record()), GuidKey.t()) :: R.bool()
  defrust matches?(record, guid) do
    record_id(record) == some(guid) or override_key(record) == some(guid)
  end

  # Finds a segment among a record's static descendants, through ordinary containers but
  # never into an instance.
  @spec find_static_segment(R.ref(source_index()), GuidKey.t(), GuidKey.t()) :: static_segment()
  defrust find_static_segment(index, parent_id, guid) do
    found = Vec.new()

    for top <- children_of(index, parent_id) do
      collect_static(index, deref(top), deref(top), guid, mut_ref(found))
    end

    if found.len() == 1 do
      {record, top} = found[0]
      struct_literal(StaticSegment, count: 1, record: some(record), top: some(top))
    else
      struct_literal(StaticSegment, count: found.len(), record: nil, top: nil)
    end
  end

  @spec collect_static(
          R.ref(source_index()),
          GuidKey.t(),
          GuidKey.t(),
          GuidKey.t(),
          R.mut_ref(R.vec({GuidKey.t(), GuidKey.t()}))
        ) :: R.unit()
  defrust collect_static(index, id, top, guid, found) do
    case source(index, id) do
      {:some, record} ->
        if matches?(record, guid) do
          found.push({id, top})
        else
          if symbol_id(record).is_none() do
            for child <- children_of(index, id) do
              collect_static(index, deref(child), top, guid, found)
            end
          end
        end

      :none ->
        :ok
    end
  end

  # Whether a path resolves in a component's own source tree, following instance links.
  @spec resolves_in_source_component?(R.ref(source_index()), GuidKey.t(), R.slice(GuidKey.t())) ::
          R.bool()
  defrust resolves_in_source_component?(index, component_id, path) do
    resolves_from?(index, component_id, path, 0)
  end

  @spec resolves_from?(R.ref(source_index()), GuidKey.t(), R.slice(GuidKey.t()), R.usize()) ::
          R.bool()
  defrust resolves_from?(index, current, path, position) do
    with {:some, segment} <- path.get(position),
         {:some, record} <- source(index, current) do
      if position == 0 and matches?(record, deref(segment)) do
        resolves_from?(index, current, path, position + 1)
      else
        case find_static_segment(index, current, deref(segment)).record do
          {:some, _found} when position + 1 == path.len() ->
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
