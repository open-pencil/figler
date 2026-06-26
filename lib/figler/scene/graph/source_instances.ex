defmodule Figler.Scene.Graph.SourceInstances do
  @moduledoc """
  Selects source instance seeds eligible for effective graph resolver stages.
  """

  alias Figler.Scene.Graph
  alias Figler.Scene.Graph.GUID
  alias Figler.Scene.Graph.SeedNode

  @doc """
  Returns source instance seeds that should participate in resolver stages.
  """
  @spec list(Graph.t()) :: [SeedNode.t()]
  def list(%Graph{} = graph) do
    focus = focus_set(graph)

    Enum.flat_map(graph.seed_nodes, fn
      {guid, %{origin: :source, node_type: "instance"} = seed} ->
        if (is_nil(focus) or MapSet.member?(focus, guid)) and
             not opaque_definition_instance?(graph, guid),
           do: [seed],
           else: []

      _entry ->
        []
    end)
  end

  defp opaque_definition_instance?(graph, guid) do
    graph
    |> definition_symbol_ancestors(guid)
    |> Enum.any?(&(not focused_source?(graph, &1)))
  end

  defp definition_symbol_ancestors(graph, guid) do
    case Map.get(graph.nodes, guid) do
      %{parent_guid: parent_guid} when is_binary(parent_guid) ->
        graph
        |> ancestor_nodes(parent_guid)
        |> Enum.filter(&(&1.node_type == "symbol"))
        |> Enum.map(&GUID.parse!(&1.guid))

      _node ->
        []
    end
  end

  defp focused_source?(graph, guid) do
    guid in Keyword.get(graph.options, :focus, [])
  end

  defp ancestor_nodes(graph, parent_guid) do
    parent_guid
    |> GUID.parse()
    |> then(&Map.get(graph.nodes, &1))
    |> case do
      %{parent_guid: next_parent_guid} = node when is_binary(next_parent_guid) ->
        [node | ancestor_nodes(graph, next_parent_guid)]

      nil ->
        []

      node ->
        [node]
    end
  end

  defp focus_set(graph) do
    case Keyword.get(graph.options, :focus) do
      nil -> nil
      [] -> nil
      focus -> focus |> Enum.flat_map(&source_subtree(graph, &1)) |> MapSet.new()
    end
  end

  defp source_subtree(graph, guid) do
    children = Map.get(graph.children, guid, [])
    [guid | Enum.flat_map(children, &source_subtree(graph, &1))]
  end
end
