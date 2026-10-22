defmodule Figler.Codegen.Native.Graph.Occurrence do
  @moduledoc """
  One use of a source record in an interpreted page tree, for the native interpreter.

  An instance expands its component's subtree, and every layer of that expansion is a separate
  occurrence with its own effective `properties`. Paths address occurrences below an owner by
  GUID or override key, never inside a nested instance.
  """

  use RustQ.Meta,
    rust_sources: [
      "deps/kiwi_codec/codegen/kiwi_codec/rustler_generator/templates/records_runtime.rs"
    ],
    callable_modules: [
      Figler.Codegen.Native.Graph.Records,
      Figler.Codegen.Native.Graph.SourceIndex
    ]

  alias RustQ.Type, as: R

  @typep occurrence :: %{
           required(:source_id) => GuidKey.t(),
           required(:override_key) => R.option(GuidKey.t()),
           required(:main_component_id) => R.option(GuidKey.t()),
           required(:main_component_override_key) => R.option(GuidKey.t()),
           required(:source_component_id) => R.option(GuidKey.t()),
           required(:source_component_override_key) => R.option(GuidKey.t()),
           required(:derived_size) => R.option(KiwiRecord.t()),
           required(:slot_content_id) => R.option(GuidKey.t()),
           required(:default_instance_name) => R.option(String.t()),
           required(:properties) => KiwiRecord.t(),
           required(:children) => R.vec(occurrence()),
           required(:property_claims) => R.vec(property_claim()),
           required(:binding_claims) => R.vec(binding_claim()),
           required(:layout_scale) => R.f64(),
           required(:has_own_name) => R.bool(),
           required(:bound_fields) => HashMap.t(R.u32(), R.u32()),
           required(:replaced_components) => R.vec(GuidKey.t()),
           required(:overridden) => HashSet.t(R.u32())
         }

  # Fields an owner's override set on a layer of its expansion.
  @typep property_claim :: %{
           required(:declared_by) => GuidKey.t(),
           required(:path) => R.vec(GuidKey.t()),
           required(:properties) => KiwiRecord.t()
         }

  # A field a component property bound on a record.
  @typep binding_claim :: %{
           required(:definition_id) => GuidKey.t(),
           required(:field) => bound_field(),
           required(:origin) => origin()
         }

  @typep bound_field :: :visible | :text_data | :symbol_data | :slot_content
  @typep origin :: :default | :assignment

  # Segment lookups of the occurrences already searched under one owner, by index path. They
  # stay valid while the subtree's shape does.
  @typep segment_table :: HashMap.t(GuidKey.t(), R.vec(R.vec(R.usize())))
  @typep segment_tables :: HashMap.t(R.vec(R.usize()), segment_table())

  @doc false
  @spec items() :: [term()]
  def items do
    __rustq_type_items__() ++
      RustQ.Meta.AST.functions!(__MODULE__, [
        :instance?,
        :root_guid?,
        :find_segment,
        :find_within,
        :resolve_path,
        :resolve_segments,
        :segment_matches,
        :segment_lookup,
        :collect_segments,
        :new_segment_keys,
        :segment_keys,
        :get_at,
        :at_mut
      ])
  end

  # Whether this occurrence expands a component.
  @spec instance?(R.ref(occurrence())) :: R.bool()
  defrust(instance?(occurrence), do: occurrence.main_component_id.is_some())

  # Whether `guid` addresses the root of this occurrence's expansion.
  @spec root_guid?(R.ref(occurrence()), GuidKey.t()) :: R.bool()
  defrust root_guid?(owner, guid) do
    symbol_id(ref(owner.properties)) == some(guid) or
      owner.main_component_override_key == some(guid) or
      owner.source_component_override_key == some(guid) or
      owner.source_component_id == some(guid)
  end

  # Finds one segment below `root`, through ordinary containers but never into a nested
  # instance: the index path to it, or how many occurrences matched.
  @spec find_segment(R.ref(occurrence()), GuidKey.t()) :: R.result(R.vec(R.usize()), R.usize())
  defrust find_segment(root, guid) do
    found = Vec.new()

    for {index, child} <- root.children.iter().enumerate() do
      find_within(child, [index], guid, mut_ref(found))
    end

    if found.len() == 1, do: ok(found.remove(0)), else: err(found.len())
  end

  @spec find_within(
          R.ref(occurrence()),
          R.vec(R.usize()),
          GuidKey.t(),
          R.mut_ref(R.vec(R.vec(R.usize())))
        ) :: R.unit()
  defrust find_within(node, path, guid, found) do
    cond do
      node.override_key == some(guid) or node.source_id == guid ->
        found.push(path)

      not instance?(node) ->
        for {index, child} <- node.children.iter().enumerate() do
          child_path = path.clone()
          child_path.push(index)
          find_within(child, child_path, guid, found)
        end

      true ->
        :ok
    end
  end

  # Resolves an owner's declared path to an index path in its subtree, or the first segment
  # that matches no occurrence or more than one, with the match count. `tables` keeps the
  # segment lookups of every level searched, for the owner's other paths.
  @spec resolve_path(R.ref(occurrence()), R.slice(GuidKey.t()), R.mut_ref(segment_tables())) ::
          R.result(R.vec(R.usize()), {GuidKey.t(), R.usize()})
  defrust resolve_path(owner, path, tables) do
    case path.first() do
      {:some, first} ->
        start = if root_guid?(owner, deref(first)), do: 1, else: 0
        resolve_segments(owner, path, start, Vec.new(), tables)

      :none ->
        ok(Vec.new())
    end
  end

  @spec resolve_segments(
          R.ref(occurrence()),
          R.slice(GuidKey.t()),
          R.usize(),
          R.vec(R.usize()),
          R.mut_ref(segment_tables())
        ) :: R.result(R.vec(R.usize()), {GuidKey.t(), R.usize()})
  defrust resolve_segments(owner, path, position, at, tables) do
    case path.get(position) do
      {:some, guid} ->
        matches = segment_matches(owner, at, deref(guid), tables)

        if matches.len() == 1 do
          next = at.clone()
          next.extend_from_slice(ref(matches[0]))
          resolve_segments(owner, path, position + 1, next, tables)
        else
          err({deref(guid), matches.len()})
        end

      :none ->
        ok(at)
    end
  end

  @spec segment_matches(
          R.ref(occurrence()),
          R.slice(R.usize()),
          GuidKey.t(),
          R.mut_ref(segment_tables())
        ) :: R.vec(R.vec(R.usize()))
  defrust segment_matches(owner, at, guid, tables) do
    table = tables.entry(at.to_vec()).or_insert_with(fn -> segment_lookup(get_at(owner, at)) end)
    table.get(ref(guid)).cloned().unwrap_or_default()
  end

  # Every GUID and override key under `root` with the index paths of its matches, as
  # `find_segment` finds them: never inside an instance, nor below an ancestor that already
  # matched the same key.
  @spec segment_lookup(R.ref(occurrence())) :: segment_table()
  defrust segment_lookup(root) do
    table = HashMap.new()

    for {index, child} <- root.children.iter().enumerate() do
      collect_segments(child, [index], ref(HashSet.new()), mut_ref(table))
    end

    table
  end

  @spec collect_segments(
          R.ref(occurrence()),
          R.vec(R.usize()),
          R.ref(HashSet.t(GuidKey.t())),
          R.mut_ref(segment_table())
        ) :: R.unit()
  defrust collect_segments(node, path, matched, table) do
    new_keys = new_segment_keys(node, matched)

    for key <- new_keys.iter() do
      table.entry(deref(key)).or_default().push(path.clone())
    end

    if not instance?(node) do
      matched = matched.clone()
      matched.extend(new_keys)

      for {index, child} <- node.children.iter().enumerate() do
        child_path = path.clone()
        child_path.push(index)
        collect_segments(child, child_path, ref(matched), table)
      end
    end
  end

  @spec new_segment_keys(R.ref(occurrence()), R.ref(HashSet.t(GuidKey.t()))) ::
          R.vec(GuidKey.t())
  defrust new_segment_keys(node, matched) do
    for key <- segment_keys(node), not matched.contains(ref(key)), do: key
  end

  # An occurrence is addressed by its override key and its source GUID.
  @spec segment_keys(R.ref(occurrence())) :: R.vec(GuidKey.t())
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
    case path.split_first() do
      {:some, {index, rest}} -> get_at(ref(occurrence.children[deref(index)]), rest)
      :none -> occurrence
    end
  end

  @spec at_mut(R.mut_ref(occurrence(), R.lifetime(:a)), R.slice(R.usize())) ::
          R.mut_ref(occurrence(), R.lifetime(:a))
  defrust at_mut(occurrence, path) do
    case path.split_first() do
      {:some, {index, rest}} -> at_mut(mut_ref(occurrence.children[deref(index)]), rest)
      :none -> occurrence
    end
  end
end
