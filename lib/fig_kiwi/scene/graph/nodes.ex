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
    %Graph{graph | children: Map.update(graph.children, parent, [child], &append_once(&1, child))}
  end

  @doc """
  Removes a subtree rooted at `guid`.
  """
  @spec remove(Graph.t(), GUID.graph_guid()) :: Graph.t()
  def remove(%Graph{} = graph, guid) do
    guids = subtree(graph, guid)
    Enum.reduce(guids, graph, &delete_one(&2, &1))
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

  defp delete_one(%Graph{} = graph, guid) do
    graph
    |> remove_indexes(guid)
    |> then(fn %Graph{} = graph ->
      %Graph{
        graph
        | nodes: Map.delete(graph.nodes, guid),
          seed_nodes: Map.delete(graph.seed_nodes, guid),
          children: delete_child_refs(graph.children, guid),
          clone_index: delete_clone_refs(graph.clone_index, guid),
          provenance: Map.delete(graph.provenance, guid)
      }
    end)
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
  defp add_index(index, key, guid), do: Map.update(index, key, [guid], &append_once(&1, guid))

  defp remove_index(index, nil, _guid), do: index
  defp remove_index(index, "", _guid), do: index

  defp remove_index(index, key, guid) do
    Map.update(index, key, [], &Enum.reject(&1, fn value -> value == guid end))
  end

  defp append_once(values, value) do
    if value in values, do: values, else: values ++ [value]
  end

  defp delete_child_refs(children, guid) do
    children
    |> Map.delete(guid)
    |> Map.new(fn {parent, child_guids} ->
      {parent, Enum.reject(child_guids, &(&1 == guid))}
    end)
  end

  defp delete_clone_refs(clone_index, guid) do
    Map.reject(clone_index, fn {_key, clone_guid} -> clone_guid == guid end)
  end
end
