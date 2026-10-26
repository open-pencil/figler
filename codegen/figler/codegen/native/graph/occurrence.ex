defmodule Figler.Codegen.Native.Graph.Occurrence do
  @moduledoc """
  One use of a source record in an interpreted page tree, for the native interpreter.

  An instance expands its component's subtree, and every layer of that expansion is a separate
  occurrence with its own effective `properties`. Paths address occurrences below an owner by
  GUID or override key, never inside a nested instance.
  """

  use RustQ.Meta,
    callable_modules: [
      Figler.Codegen.Native.Graph.Records,
      Figler.Codegen.Native.Graph.SourceIndex
    ]

  alias Figler.Codegen.Native.Graph.Records
  alias KiwiCodec.RustlerGenerator.Records, as: Kiwi
  alias RustQ.Type, as: R

  @typep occurrence :: %{
           required(:source_id) => Records.guid_key(),
           required(:override_key) => R.option(Records.guid_key()),
           required(:main_component_id) => R.option(Records.guid_key()),
           required(:main_component_override_key) => R.option(Records.guid_key()),
           required(:source_component_id) => R.option(Records.guid_key()),
           required(:source_component_override_key) => R.option(Records.guid_key()),
           required(:derived_size) => R.option(Kiwi.kiwi_record()),
           required(:slot_content_id) => R.option(Records.guid_key()),
           required(:default_instance_name) => R.option(String.t()),
           required(:properties) => Kiwi.kiwi_record(),
           required(:children) => R.vec(occurrence()),
           required(:property_claims) => R.vec(property_claim()),
           required(:binding_claims) => R.vec(binding_claim()),
           required(:layout_scale) => R.f64(),
           required(:has_own_name) => R.bool(),
           required(:bound_fields) => HashMap.t(R.u32(), R.u32()),
           required(:replaced_components) => R.vec(Records.guid_key()),
           required(:overridden) => HashSet.t(R.u32())
         }

  # Fields an owner's override set on a layer of its expansion.
  @typep property_claim :: %{
           required(:declared_by) => Records.guid_key(),
           required(:path) => R.vec(Records.guid_key()),
           required(:properties) => Kiwi.kiwi_record()
         }

  # A field a component property bound on a record.
  @typep binding_claim :: %{
           required(:definition_id) => Records.guid_key(),
           required(:field) => bound_field(),
           required(:origin) => origin()
         }

  @typep bound_field :: :visible | :text_data | :symbol_data | :slot_content
  @typep origin :: :default | :assignment

  # Segment lookups of the occurrences already searched under one owner, by index path. They
  # stay valid while the subtree's shape does.
  @typep segment_table :: HashMap.t(Records.guid_key(), R.vec(R.vec(R.usize())))
  @typep segment_tables :: HashMap.t(R.vec(R.usize()), segment_table())

  @doc "The Rust types and functions this module defines."
  @spec items() :: [term()]
  def items, do: __rustq_items__()

  # Whether this occurrence expands a component.
  @spec instance?(R.ref(occurrence())) :: R.bool()
  defrust(instance?(occurrence), do: occurrence.main_component_id.is_some())

  # Whether `guid` addresses the root of this occurrence's expansion.
  @spec root_guid?(R.ref(occurrence()), Records.guid_key()) :: R.bool()
  defrust root_guid?(owner, guid) do
    symbol_id(ref(owner.properties)) == some(guid) or
      owner.main_component_override_key == some(guid) or
      owner.source_component_override_key == some(guid) or
      owner.source_component_id == some(guid)
  end

  # Finds one segment below `root`, through ordinary containers but never into a nested
  # instance: the index path to it, or how many occurrences matched.
  @spec find_segment(R.ref(occurrence()), Records.guid_key()) ::
          R.result(R.vec(R.usize()), R.usize())
  defrust find_segment(root, guid) do
    found =
      root.children
      |> Enum.with_index()
      |> Enum.reduce([], fn {child, index}, found -> find_within(child, [index], guid, found) end)

    case found do
      [path] -> {:ok, path.clone()}
      found -> {:error, length(found)}
    end
  end

  # `found`, with the index paths of the occurrences matching `guid` at and below `node`.
  @spec find_within(
          R.ref(occurrence()),
          R.vec(R.usize()),
          Records.guid_key(),
          R.vec(R.vec(R.usize()))
        ) :: R.vec(R.vec(R.usize()))
  defrust find_within(node, path, guid, found) do
    cond do
      node.override_key == some(guid) or node.source_id == guid ->
        found ++ [path]

      instance?(node) ->
        found

      true ->
        node.children
        |> Enum.with_index()
        |> Enum.reduce(found, fn {child, index}, found ->
          find_within(child, path ++ [index], guid, found)
        end)
    end
  end

  # Resolves an owner's declared path to an index path in its subtree, or the first segment
  # that matches no occurrence or more than one, with the match count. `tables` keeps the
  # segment lookups of every level searched, for the owner's other paths.
  @spec resolve_path(
          R.ref(occurrence()),
          R.slice(Records.guid_key()),
          R.mut_ref(segment_tables())
        ) ::
          R.result(R.vec(R.usize()), {Records.guid_key(), R.usize()})
  defrust resolve_path(owner, path, tables) do
    case path do
      [first | _rest] ->
        start = if root_guid?(owner, first), do: 1, else: 0
        resolve_segments(owner, path, start, [], tables)

      [] ->
        {:ok, []}
    end
  end

  @spec resolve_segments(
          R.ref(occurrence()),
          R.slice(Records.guid_key()),
          R.usize(),
          R.vec(R.usize()),
          R.mut_ref(segment_tables())
        ) :: R.result(R.vec(R.usize()), {Records.guid_key(), R.usize()})
  defrust resolve_segments(owner, path, position, at, tables) do
    case Enum.at(path, position) do
      {:some, guid} ->
        case segment_matches(owner, at, guid, tables) do
          [segment] -> resolve_segments(owner, path, position + 1, at ++ segment, tables)
          matches -> {:error, {guid, length(matches)}}
        end

      :none ->
        {:ok, at}
    end
  end

  @spec segment_matches(
          R.ref(occurrence()),
          R.slice(R.usize()),
          Records.guid_key(),
          R.mut_ref(segment_tables())
        ) :: R.vec(R.vec(R.usize()))
  defrust segment_matches(owner, at, guid, tables) do
    tables.entry(at.to_vec()).or_insert_with(fn -> segment_lookup(get_at(owner, at)) end)
    Map.get(tables[at], guid, [])
  end

  # Every GUID and override key under `root` with the index paths of its matches, as
  # `find_segment` finds them: never inside an instance, nor below an ancestor that already
  # matched the same key.
  @spec segment_lookup(R.ref(occurrence())) :: segment_table()
  defrust segment_lookup(root) do
    root.children
    |> Enum.with_index()
    |> Enum.reduce(%{}, fn {child, index}, table ->
      collect_segments(child, [index], ref(MapSet.new()), table)
    end)
  end

  # `table`, with the keys at and below `node` that no ancestor matched.
  @spec collect_segments(
          R.ref(occurrence()),
          R.vec(R.usize()),
          R.ref(HashSet.t(Records.guid_key())),
          segment_table()
        ) :: segment_table()
  defrust collect_segments(node, path, matched, table) do
    new_keys = new_segment_keys(node, matched)

    table =
      Enum.reduce(new_keys, table, fn key, table ->
        Map.update(table, key, [path], fn paths -> paths ++ [path] end)
      end)

    if instance?(node) do
      table
    else
      matched = MapSet.union(matched, MapSet.new(new_keys))

      node.children
      |> Enum.with_index()
      |> Enum.reduce(table, fn {child, index}, table ->
        collect_segments(child, path ++ [index], matched, table)
      end)
    end
  end

  @spec new_segment_keys(R.ref(occurrence()), R.ref(HashSet.t(Records.guid_key()))) ::
          R.vec(Records.guid_key())
  defrust new_segment_keys(node, matched) do
    for key <- segment_keys(node), not MapSet.member?(matched, key), do: key
  end

  # An occurrence is addressed by its override key and its source GUID.
  @spec segment_keys(R.ref(occurrence())) :: R.vec(Records.guid_key())
  defrust segment_keys(node) do
    case node.override_key do
      {:some, key} when key != node.source_id -> [key, node.source_id]
      _ -> [node.source_id]
    end
  end

  # The occurrence at an index path.
  @spec get_at(R.ref(occurrence(), R.lifetime(:a)), R.slice(R.usize())) ::
          R.ref(occurrence(), R.lifetime(:a))
  defrust get_at(occurrence, path) do
    case path do
      [index | rest] -> get_at(ref(occurrence.children[index]), rest)
      [] -> occurrence
    end
  end

  @spec at_mut(R.mut_ref(occurrence(), R.lifetime(:a)), R.slice(R.usize())) ::
          R.mut_ref(occurrence(), R.lifetime(:a))
  defrust at_mut(occurrence, path) do
    case path do
      [index | rest] -> at_mut(mut_ref(occurrence.children[index]), rest)
      [] -> occurrence
    end
  end
end
