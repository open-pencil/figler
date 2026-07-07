defmodule Figler.Scene.Graph.Nodes do
  @moduledoc """
  Graph node mutation helpers.
  """

  alias Figler.Scene.Graph
  alias Figler.Scene.Graph.GUID
  alias Figler.Scene.Graph.Seed.Node, as: SeedNode
  alias Figler.Scene.Node

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
  @spec remove(Graph.t(), GUID.graph_guid(), keyword()) :: Graph.t()
  def remove(%Graph{} = graph, guid, opts \\ []) do
    remove_many(graph, [guid], opts)
  end

  @doc """
  Removes multiple subtrees in one batch.
  """
  @spec remove_many(Graph.t(), [GUID.graph_guid()], keyword()) :: Graph.t()
  def remove_many(%Graph{} = graph, root_guids, opts \\ []) when is_list(root_guids) do
    guids = Enum.flat_map(root_guids, &subtree(graph, &1))
    guid_set = MapSet.new(guids)

    %Graph{
      graph
      | nodes: Map.drop(graph.nodes, guids),
        seed_nodes: Map.drop(graph.seed_nodes, guids),
        children: delete_child_refs(graph.children, guid_set),
        provenance: Map.drop(graph.provenance, guids)
    }
    |> maybe_remove_index_entries(guid_set, opts)
  end

  @doc """
  Removes all direct children under a parent in one batch.
  """
  @spec clear_children(Graph.t(), GUID.graph_guid(), keyword()) :: Graph.t()
  def clear_children(%Graph{} = graph, parent_guid, opts \\ []) do
    root_guids = Map.get(graph.children, parent_guid, [])
    guids = Enum.flat_map(root_guids, &subtree(graph, &1))
    guid_set = MapSet.new(guids)

    %Graph{
      graph
      | nodes: Map.drop(graph.nodes, guids),
        seed_nodes: Map.drop(graph.seed_nodes, guids),
        children: graph.children |> Map.drop(guids) |> Map.put(parent_guid, []),
        provenance: Map.drop(graph.provenance, guids)
    }
    |> maybe_remove_index_entries(guid_set, opts)
  end

  defp maybe_remove_index_entries(%Graph{} = graph, guid_set, opts) do
    if Keyword.get(opts, :indexes, true) do
      %Graph{
        graph
        | clone_index: delete_clone_refs(graph.clone_index, guid_set),
          clone_source_index: delete_clone_refs(graph.clone_source_index, guid_set),
          by_type: remove_index_entries(graph.by_type, guid_set),
          by_name: remove_index_entries(graph.by_name, guid_set)
      }
    else
      graph
    end
  end

  @doc """
  Rebuilds type/name lookup indexes from current graph nodes.
  """
  @spec reindex(Graph.t()) :: Graph.t()
  def reindex(%Graph{} = graph) do
    %Graph{
      graph
      | by_type: group_nodes(graph.nodes, & &1.node_type),
        by_name: group_nodes(graph.nodes, & &1.name)
    }
  end

  @doc """
  Returns subtree GUIDs in descendants-first order.
  """
  @spec subtree(Graph.t(), GUID.graph_guid()) :: [GUID.graph_guid()]
  def subtree(%Graph{} = graph, guid) do
    graph
    |> subtree(guid, [])
    |> Enum.reverse()
  end

  defp group_nodes(nodes, key_fun) do
    Enum.reduce(nodes, %{}, fn {guid, node}, acc ->
      case key_fun.(node) do
        nil -> acc
        "" -> acc
        key -> Map.update(acc, key, [guid], &[guid | &1])
      end
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
  defp add_index(index, key, guid), do: Map.update(index, key, [guid], &[guid | &1])

  defp remove_index(index, nil, _guid), do: index
  defp remove_index(index, "", _guid), do: index

  defp remove_index(index, key, guid) do
    Map.update(index, key, [], &Enum.reject(&1, fn value -> value == guid end))
  end

  defp subtree(%Graph{} = graph, guid, acc) do
    acc =
      graph.children
      |> Map.get(guid, [])
      |> Enum.reduce(acc, &subtree(graph, &1, &2))

    [guid | acc]
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
