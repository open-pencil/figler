defmodule FigKiwi.Scene.Graph.Nodes do
  @moduledoc """
  Graph node mutation helpers.
  """

  alias FigKiwi.Scene.Graph
  alias FigKiwi.Scene.Graph.GUID
  alias FigKiwi.Scene.Graph.SeedNode
  alias FigKiwi.Scene.Node

  @doc """
  Inserts or replaces a node and keeps type/name indexes current.
  """
  @spec put(Graph.t(), GUID.graph_guid(), Node.t(), SeedNode.t() | nil) :: Graph.t()
  def put(%Graph{} = graph, guid, %Node{} = node, seed \\ nil) do
    graph
    |> remove_indexes(guid)
    |> then(fn %Graph{} = graph ->
      %Graph{
        graph
        | nodes: Map.put(graph.nodes, guid, node),
          seed_nodes: put_seed(graph.seed_nodes, guid, seed),
          by_type: add_index(graph.by_type, node.node_type, guid),
          by_name: add_index(graph.by_name, node.name, guid)
      }
    end)
  end

  @doc """
  Adds `child` to `parent` if not already present.
  """
  @spec child(Graph.t(), GUID.graph_guid(), GUID.graph_guid()) :: Graph.t()
  def child(%Graph{} = graph, parent, child) do
    %Graph{
      graph
      | children: Map.update(graph.children, parent, [child], &append_child(&1, child))
    }
  end

  @doc """
  Removes a subtree rooted at `guid`.
  """
  @spec remove(Graph.t(), GUID.graph_guid()) :: Graph.t()
  def remove(%Graph{} = graph, guid) do
    guids = subtree(graph, guid)
    guid_set = MapSet.new(guids)

    %Graph{
      graph
      | nodes: Map.drop(graph.nodes, guids),
        seed_nodes: Map.drop(graph.seed_nodes, guids),
        children: delete_child_refs(graph.children, guid_set),
        clone_index: delete_clone_refs(graph.clone_index, guid_set),
        clone_source_index: delete_clone_refs(graph.clone_source_index, guid_set),
        provenance: Map.drop(graph.provenance, guids),
        by_type: remove_index_entries(graph.by_type, guid_set),
        by_name: remove_index_entries(graph.by_name, guid_set)
    }
  end

  @doc """
  Returns subtree GUIDs in descendants-first order.
  """
  @spec subtree(Graph.t(), GUID.graph_guid()) :: [GUID.graph_guid()]
  def subtree(%Graph{} = graph, guid) do
    descendants =
      graph.children
      |> Map.get(guid, [])
      |> Enum.flat_map(&subtree(graph, &1))

    descendants ++ [guid]
  end

  defp remove_indexes(%Graph{} = graph, guid) do
    case Map.get(graph.nodes, guid) do
      nil ->
        graph

      %Node{} = node ->
        %Graph{
          graph
          | by_type: remove_index(graph.by_type, node.node_type, guid),
            by_name: remove_index(graph.by_name, node.name, guid)
        }
    end
  end

  defp put_seed(seed_nodes, _guid, nil), do: seed_nodes
  defp put_seed(seed_nodes, guid, seed), do: Map.put(seed_nodes, guid, seed)

  defp add_index(index, nil, _guid), do: index
  defp add_index(index, "", _guid), do: index
  defp add_index(index, key, guid), do: Map.update(index, key, [guid], &[guid | &1])

  defp remove_index(index, nil, _guid), do: index
  defp remove_index(index, "", _guid), do: index

  defp remove_index(index, key, guid) do
    Map.update(index, key, [], &Enum.reject(&1, fn value -> value == guid end))
  end

  defp append_child(values, value), do: values ++ [value]

  defp remove_index_entries(index, guid_set) do
    Map.new(index, fn {key, guids} ->
      {key, Enum.reject(guids, &MapSet.member?(guid_set, &1))}
    end)
  end

  defp delete_child_refs(children, guid_set) do
    children
    |> Map.reject(fn {parent, _child_guids} -> MapSet.member?(guid_set, parent) end)
    |> Map.new(fn {parent, child_guids} ->
      {parent, Enum.reject(child_guids, &MapSet.member?(guid_set, &1))}
    end)
  end

  defp delete_clone_refs(clone_index, guid_set) do
    Map.reject(clone_index, fn {_key, clone_guid} -> MapSet.member?(guid_set, clone_guid) end)
  end
end
