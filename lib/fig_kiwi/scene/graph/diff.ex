defmodule FigKiwi.Scene.Graph.Diff do
  @moduledoc false

  alias FigKiwi.Scene.Graph
  alias FigKiwi.Scene.Graph.GUID
  alias FigKiwi.Scene.Graph.SeedNode
  alias FigKiwi.Scene.Node

  @doc false
  def run(%Graph{} = graph, opts) when is_list(opts) do
    graph
    |> diff_guids(opts)
    |> Enum.flat_map(&diff_guid(graph, &1))
  end

  defp diff_guids(graph, opts) do
    case Keyword.fetch(opts, :root) do
      {:ok, root} ->
        root_guid = GUID.parse!(root)
        [root_guid | descendant_guids(graph, root_guid)]

      :error ->
        Map.keys(graph.nodes)
    end
  end

  defp descendant_guids(graph, guid) do
    graph.children
    |> Map.get(guid, [])
    |> Enum.flat_map(fn child_guid -> [child_guid | descendant_guids(graph, child_guid)] end)
  end

  defp diff_guid(graph, guid) do
    with %Node{} = resolved <- Map.get(graph.nodes, guid),
         %Node{} = source <- source_node(graph, guid),
         changes when changes != [] <- node_changes(source, resolved) do
      [%{guid: GUID.format(guid), source: source, resolved: resolved, changed: changes}]
    else
      _value -> []
    end
  end

  defp source_node(graph, guid) do
    graph.seed_nodes
    |> Map.get(guid)
    |> case do
      %SeedNode{} = seed -> SeedNode.to_node(seed)
      nil -> nil
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
