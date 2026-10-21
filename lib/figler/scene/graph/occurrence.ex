defmodule Figler.Scene.Graph.Occurrence do
  @moduledoc """
  One use of a source record in an interpreted page tree.

  An instance expands its component's subtree; every layer of that expansion
  is a separate occurrence with its own effective `properties`, so overrides on
  one instance never reach another use of the same component. This mirrors
  OpenPencil's occurrence-scoped instance interpreter, which Figler follows as
  its reference reader (see `Figler.Scene.Graph.Occurrence.Interpreter`).

  `properties` is the effective sparse `NodeChange` map.
  """

  alias Figler.Scene.Graph.Occurrence.GUID
  alias Figler.Scene.Graph.Occurrence.Tree

  @enforce_keys [:source_id, :properties]
  defstruct [
    :source_id,
    :override_key,
    :main_component_id,
    :main_component_override_key,
    :source_component_id,
    :source_component_override_key,
    :derived_size,
    :slot_content_id,
    :default_instance_name,
    properties: %{},
    children: [],
    property_claims: [],
    binding_claims: [],
    layout_scale: 1.0,
    has_own_name: false,
    bound_fields: %{},
    replaced_components: [],
    overridden: MapSet.new()
  ]

  @type claim :: %{declared_by: GUID.t(), path: [GUID.t()], properties: map()}

  @type t :: %__MODULE__{
          source_id: GUID.t(),
          override_key: GUID.t() | nil,
          main_component_id: GUID.t() | nil,
          main_component_override_key: GUID.t() | nil,
          source_component_id: GUID.t() | nil,
          source_component_override_key: GUID.t() | nil,
          derived_size: map() | nil,
          slot_content_id: GUID.t() | nil,
          default_instance_name: String.t() | nil,
          properties: map(),
          children: [t()],
          property_claims: [claim()],
          binding_claims: [map()],
          layout_scale: number(),
          has_own_name: boolean(),
          bound_fields: %{atom() => non_neg_integer()},
          replaced_components: [GUID.t()],
          overridden: MapSet.t(atom())
        }

  @shape %{children: &__MODULE__.children/1, instance?: &__MODULE__.instance?/1}

  @doc false
  def children(%__MODULE__{children: children}), do: children

  @doc "Whether this occurrence expands a component."
  @spec instance?(t()) :: boolean()
  def instance?(%__MODULE__{main_component_id: main_component_id}), do: main_component_id != nil

  @doc """
  Finds one segment below `root`, through ordinary containers but never into a
  nested instance. Returns the index path to it, or `{:error, count}`.
  """
  @spec find_segment(t(), GUID.t()) :: {:ok, [non_neg_integer()]} | {:error, non_neg_integer()}
  def find_segment(%__MODULE__{} = root, guid) do
    matches? = fn node -> node.override_key == guid or node.source_id == guid end

    case Tree.find_within_boundary(root.children, @shape, matches?) do
      [{_match, _top, path}] -> {:ok, path}
      found -> {:error, length(found)}
    end
  end

  @doc "Whether `guid` addresses the root of this occurrence's expansion."
  @spec root_guid?(t(), GUID.t()) :: boolean()
  def root_guid?(%__MODULE__{} = owner, guid) do
    GUID.key(get_in(owner.properties, [:symbol_data, :symbol_id])) == guid or
      owner.main_component_override_key == guid or
      owner.source_component_override_key == guid or
      owner.source_component_id == guid
  end

  @doc """
  Resolves an owner's declared path to an index path in its subtree.

  Returns `{:error, segment, count}` for the first segment that matches no
  occurrence or more than one.
  """
  @spec resolve_path(t(), [GUID.t()]) ::
          {:ok, [non_neg_integer()]} | {:error, GUID.t(), non_neg_integer()}
  def resolve_path(%__MODULE__{} = owner, path) do
    {result, _tables} = resolve_path(owner, path, %{})
    result
  end

  @doc """
  Resolves a path like `resolve_path/2`, reusing and extending `tables`: the segment lookups of
  occurrences already searched under `owner`. They stay valid while the subtree's shape does,
  so a run of claims or derived entries on one owner searches each level once.
  """
  @spec resolve_path(t(), [GUID.t()], map()) ::
          {{:ok, [non_neg_integer()]} | {:error, GUID.t(), non_neg_integer()}, map()}
  def resolve_path(%__MODULE__{} = owner, [first | rest] = path, tables) do
    if root_guid?(owner, first),
      do: resolve_segments(owner, [], rest, [], tables),
      else: resolve_segments(owner, [], path, [], tables)
  end

  def resolve_path(%__MODULE__{}, [], tables), do: {{:ok, []}, tables}

  # Index paths of matched segments are collected in reverse, then joined.
  defp resolve_segments(_current, _at, [], segments, tables),
    do: {{:ok, segments |> Enum.reverse() |> Enum.concat()}, tables}

  defp resolve_segments(current, at, [guid | rest], segments, tables) do
    {table, tables} = segment_table(current, at, tables)

    case Map.get(table, guid, []) do
      [indexes] ->
        next = get_at(current, indexes)
        resolve_segments(next, at ++ indexes, rest, [indexes | segments], tables)

      found ->
        {{:error, guid, length(found)}, tables}
    end
  end

  defp segment_table(current, at, tables) do
    case Map.fetch(tables, at) do
      {:ok, table} ->
        {table, tables}

      :error ->
        table = segment_lookup(current)
        {table, Map.put(tables, at, table)}
    end
  end

  # Every GUID and override key under `root` with the index paths of its matches, as
  # `find_segment/2` finds them: never inside an instance, nor below an ancestor that already
  # matched the same key.
  defp segment_lookup(root) do
    root.children
    |> Enum.with_index()
    |> Enum.reduce(%{}, fn {child, index}, table ->
      collect_segments(child, [index], MapSet.new(), table)
    end)
    |> Map.new(fn {key, paths} -> {key, Enum.reverse(paths)} end)
  end

  defp collect_segments(node, path, matched, table) do
    keys = Enum.uniq(for key <- [node.override_key, node.source_id], key != nil, do: key)
    new_keys = Enum.reject(keys, &MapSet.member?(matched, &1))
    found = Enum.reverse(path)

    table =
      Enum.reduce(new_keys, table, &Map.update(&2, &1, [found], fn paths -> [found | paths] end))

    if instance?(node) do
      table
    else
      matched = Enum.reduce(new_keys, matched, &MapSet.put(&2, &1))

      node.children
      |> Enum.with_index()
      |> Enum.reduce(table, fn {child, index}, table ->
        collect_segments(child, [index | path], matched, table)
      end)
    end
  end

  @doc "The occurrence at an index path."
  @spec get_at(t(), [non_neg_integer()]) :: t()
  def get_at(occurrence, []), do: occurrence

  def get_at(occurrence, [index | rest]),
    do: occurrence.children |> Enum.fetch!(index) |> get_at(rest)

  @doc "Replaces the occurrence at an index path with `fun.(occurrence)`."
  @spec update_at(t(), [non_neg_integer()], (t() -> t())) :: t()
  def update_at(occurrence, [], fun), do: fun.(occurrence)

  def update_at(occurrence, [index | rest], fun) do
    %{
      occurrence
      | children: List.update_at(occurrence.children, index, &update_at(&1, rest, fun))
    }
  end

  @doc "Applies `fun` to every occurrence in the subtree, parents before children."
  @spec map_subtree(t(), (t() -> t())) :: t()
  def map_subtree(occurrence, fun) do
    occurrence = fun.(occurrence)
    %{occurrence | children: Enum.map(occurrence.children, &map_subtree(&1, fun))}
  end
end
