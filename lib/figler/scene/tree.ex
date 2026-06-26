defmodule Figler.Scene.Tree do
  @moduledoc """
  Lightweight tree builders for projected scene nodes and effective graphs.
  """

  alias Figler.Scene.Graph
  alias Figler.Scene.Graph.GUID
  alias Figler.Scene.Node
  alias Figler.Scene.Query

  @doc """
  Builds a nested projected scene tree from a reusable scene index/resource.
  """
  @spec projected(reference(), keyword()) :: [Node.t()] | Node.t() | nil
  def projected(index, opts) when is_list(opts) do
    depth = Keyword.get(opts, :depth, 3)

    case Keyword.fetch(opts, :root) do
      {:ok, guid} ->
        if root = Figler.Scene.node(index, guid) do
          projected_node(index, root, depth)
        end

      :error ->
        index
        |> Figler.Scene.query("//*[not(@parent_guid)]")
        |> Enum.map(&projected_node(index, &1, depth))
    end
  end

  @doc """
  Returns ancestors for a graph node GUID, ordered from root to parent.
  """
  @spec graph_ancestors(Graph.t(), String.t()) :: [Node.t()]
  def graph_ancestors(%Graph{} = graph, guid) when is_binary(guid) do
    graph_ancestors(graph, guid, [])
  end

  @doc """
  Returns all descendants for a graph node GUID in scene order.
  """
  @spec graph_descendants(Graph.t(), String.t()) :: [Node.t()]
  def graph_descendants(%Graph{} = graph, guid) when is_binary(guid) do
    graph
    |> Figler.Scene.children(guid)
    |> Enum.flat_map(fn child -> [child | graph_descendants(graph, child.guid)] end)
  end

  @doc """
  Builds a resolved graph tree.
  """
  @spec graph_tree(Graph.t(), keyword()) :: [Node.t()] | Node.t() | nil
  def graph_tree(%Graph{} = graph, opts) when is_list(opts) do
    depth = Keyword.get(opts, :depth, 3)

    case Keyword.fetch(opts, :root) do
      {:ok, guid} ->
        graph_guid = GUID.parse!(guid)

        if node = Map.get(graph.nodes, graph_guid) do
          graph_node(graph, node, depth)
        end

      :error ->
        graph
        |> Query.nodes_by_guids(graph.roots)
        |> Enum.map(&graph_node(graph, &1, depth))
    end
  end

  defp projected_node(_index, %Node{} = node, 0), do: %Node{node | children: []}

  defp projected_node(index, %Node{} = node, depth) do
    children =
      Enum.map(Figler.Scene.children(index, node.guid), &projected_node(index, &1, depth - 1))

    %Node{node | children: children}
  end

  defp graph_node(_graph, %Node{} = node, 0), do: %Node{node | children: []}

  defp graph_node(graph, %Node{} = node, depth) do
    child_nodes = Query.nodes_by_guids(graph, child_guids(graph, node.guid))
    %Node{node | children: Enum.map(child_nodes, &graph_node(graph, &1, depth - 1))}
  end

  defp graph_ancestors(%Graph{} = graph, guid, acc) do
    case Figler.Scene.parent(graph, guid) do
      nil -> acc
      %Node{guid: parent_guid} = parent -> graph_ancestors(graph, parent_guid, [parent | acc])
    end
  end

  defp child_guids(graph, guid), do: Map.get(graph.children, GUID.parse!(guid), [])
end
