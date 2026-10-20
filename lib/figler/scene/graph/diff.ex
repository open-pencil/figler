defmodule Figler.Scene.Graph.Diff do
  @moduledoc """
  Computes field-level differences between projected source nodes and resolved graph nodes.

  Diff output is used by graph debugging and fixture tooling to show exactly
  which fields instance resolution changed on a scene node.
  """

  alias Figler.Scene.Graph
  alias Figler.Scene.Graph.GUID
  alias Figler.Scene.Node
  alias Figler.Scene.Query

  @doc """
  Returns field-level changes between projected source nodes and resolved graph nodes.

  Pass `:root` to limit the diff to one graph subtree.
  """
  @spec run(Graph.t(), keyword()) :: [map()]
  def run(%Graph{} = graph, opts) when is_list(opts) do
    graph
    |> diff_guids(opts)
    |> Enum.flat_map(&diff_guid(graph, &1))
  end

  defp diff_guids(graph, opts) do
    case Keyword.fetch(opts, :root) do
      {:ok, root} ->
        root_guid = GUID.parse!(root)
        subtree_guids(graph, root_guid)

      :error ->
        Map.keys(graph.nodes)
    end
  end

  defp subtree_guids(graph, guid) do
    graph
    |> subtree_guids(guid, [])
    |> Enum.reverse()
  end

  defp subtree_guids(graph, guid, acc) do
    acc =
      graph.children
      |> Map.get(guid, [])
      |> Enum.reduce(acc, &subtree_guids(graph, &1, &2))

    [guid | acc]
  end

  defp diff_guid(graph, guid) do
    with %Node{} = resolved <- graph.nodes |> Map.get(guid) |> Query.public_node(),
         %Node{} = source <- source_node(graph, guid),
         changes when changes != [] <- node_changes(source, resolved) do
      [%{guid: GUID.format(guid), source: source, resolved: resolved, changed: changes}]
    else
      _value -> []
    end
  end

  # The source node keeps the graph node's identity, so only resolved fields differ.
  defp source_node(graph, guid) do
    with %Node{} = resolved <- graph.nodes |> Map.get(guid) |> Query.public_node(),
         %Node{} = source <- Graph.source_node(graph, GUID.format(guid)) do
      %{Query.public_node(source) | guid: resolved.guid, parent_guid: resolved.parent_guid}
    else
      _missing -> nil
    end
  end

  defp node_changes(source, resolved) do
    Node.__struct__()
    |> Map.keys()
    |> Enum.reject(&(&1 in [:__struct__, :children]))
    |> Enum.flat_map(fn field ->
      field_change(field, Map.get(source, field), Map.get(resolved, field))
    end)
  end

  defp field_change(_field, value, value), do: []

  defp field_change(field, source, resolved),
    do: [%{field: field, source: source, resolved: resolved}]
end
