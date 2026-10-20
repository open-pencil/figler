defmodule Figler.Scene.Graph.Occurrence.SourceIndex do
  @moduledoc """
  Source records by GUID, with children in saved order, prepared for the
  occurrence interpreter.
  """

  alias Figler.Scene.Graph.Occurrence.GUID
  alias Figler.Scene.Graph.Occurrence.Prepare
  alias Figler.Scene.Graph.Occurrence.Tree

  @enforce_keys [:sources, :children]
  defstruct [:sources, :children]

  @type source_record :: map()
  @type t :: %__MODULE__{
          sources: %{GUID.t() => source_record()},
          children: %{GUID.t() => [source_record()]}
        }

  @doc """
  Indexes live records, prepared for interpretation. Removed records are
  dropped and duplicate GUIDs raise.

  Pass `styles: false` to keep the values records saved instead of applying
  the shared styles they reference.
  """
  @spec new([source_record()], keyword()) :: t()
  def new(records, opts \\ []) do
    live =
      records
      |> Enum.reject(&(Map.get(&1, :phase) == :removed))
      |> Prepare.records(Keyword.get(opts, :styles, true))

    sources = Enum.reduce(live, %{}, &put_source/2)

    children =
      live
      |> Enum.filter(&(id(&1) && parent_id(&1)))
      |> Enum.group_by(&parent_id/1)
      |> Map.new(fn {parent, siblings} -> {parent, Enum.sort_by(siblings, &position/1)} end)

    %__MODULE__{sources: sources, children: children}
  end

  defp put_source(record, sources) do
    case id(record) do
      nil ->
        sources

      id when is_map_key(sources, id) ->
        raise ArgumentError, "duplicate source node #{GUID.format(id)}"

      id ->
        Map.put(sources, id, record)
    end
  end

  @spec id(source_record()) :: GUID.t() | nil
  def id(record), do: record |> Map.get(:guid) |> GUID.key()

  @spec parent_id(source_record()) :: GUID.t() | nil
  def parent_id(record), do: get_in(record, [:parent_index, :guid]) |> GUID.key()

  # Saved sibling order: the fractional position string, compared as text.
  defp position(record), do: get_in(record, [:parent_index, :position]) || ""

  @spec children(t(), GUID.t()) :: [source_record()]
  def children(%__MODULE__{children: children}, id), do: Map.get(children, id, [])

  @spec symbol_id(source_record() | nil) :: GUID.t() | nil
  def symbol_id(nil), do: nil
  def symbol_id(record), do: record |> get_in([:symbol_data, :symbol_id]) |> GUID.key()

  @doc "A path segment addresses a record by GUID or by its stable override key."
  @spec matches?(source_record(), GUID.t()) :: boolean()
  def matches?(record, guid),
    do: id(record) == guid or GUID.override_key(Map.get(record, :override_key)) == guid

  @doc """
  Finds a segment among a record's static descendants, through ordinary
  containers but never into an instance.

  Returns the match count, the single match, and the direct child holding it.
  """
  @spec find_static_segment(t(), GUID.t(), GUID.t()) ::
          %{count: non_neg_integer(), record: source_record() | nil, top: source_record() | nil}
  def find_static_segment(index, parent_id, guid) do
    shape = %{
      children: &children(index, id(&1)),
      instance?: &(symbol_id(&1) != nil)
    }

    case Tree.find_within_boundary(children(index, parent_id), shape, &matches?(&1, guid)) do
      [{record, top, _path}] -> %{count: 1, record: record, top: top}
      found -> %{count: length(found), record: nil, top: nil}
    end
  end

  @doc "Whether a path resolves in a component's own source tree, following instance links."
  @spec resolves_in_source_component?(t(), GUID.t(), [GUID.t()]) :: boolean()
  def resolves_in_source_component?(index, component_id, path) do
    path
    |> Enum.with_index()
    |> Enum.reduce_while({:continue, component_id}, fn {segment, position}, {:continue, id} ->
      resolve_source_segment(index, id, segment, position, position == length(path) - 1)
    end)
    |> Kernel.==(:resolved)
  end

  defp resolve_source_segment(index, source_id, segment, position, last?) do
    case Map.get(index.sources, source_id) do
      nil ->
        {:halt, :missing}

      source ->
        if position == 0 and matches?(source, segment) do
          {:cont, {:continue, source_id}}
        else
          follow_source_segment(index, source_id, segment, last?)
        end
    end
  end

  defp follow_source_segment(index, source_id, segment, last?) do
    case find_static_segment(index, source_id, segment) do
      %{record: nil} -> {:halt, :missing}
      %{record: _record} when last? -> {:halt, :resolved}
      %{record: record} -> next_source_component(record)
    end
  end

  defp next_source_component(record) do
    case symbol_id(record) do
      nil -> {:halt, :missing}
      component -> {:cont, {:continue, component}}
    end
  end

  @doc "Follows raw symbol references to the component an instance ultimately expands."
  @spec terminal_component(t(), GUID.t()) :: GUID.t()
  def terminal_component(index, id), do: terminal_component(index, id, MapSet.new())

  defp terminal_component(index, id, seen) do
    record = Map.get(index.sources, id)

    cond do
      MapSet.member?(seen, id) -> id
      Map.get(record || %{}, :type) != :instance -> id
      symbol_id(record) == nil -> id
      true -> terminal_component(index, symbol_id(record), MapSet.put(seen, id))
    end
  end
end
