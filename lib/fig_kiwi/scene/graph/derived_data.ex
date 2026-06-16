defmodule FigKiwi.Scene.Graph.DerivedData do
  @moduledoc """
  Applies Figma-derived symbol data to populated graph nodes.
  """

  alias FigKiwi.Scene.Graph
  alias FigKiwi.Scene.Graph.DerivedSymbolData
  alias FigKiwi.Scene.Graph.GUID
  alias FigKiwi.Scene.Graph.Patch
  alias FigKiwi.Scene.Graph.SeedNode
  alias FigKiwi.Scene.Graph.Target

  @doc """
  Applies derived data entries from an instance seed.
  """
  @spec apply(Graph.t(), SeedNode.t()) :: Graph.t()
  def apply(%Graph{} = graph, %SeedNode{derived_symbol_data: []}), do: graph

  def apply(%Graph{} = graph, %SeedNode{} = seed) do
    seed.derived_symbol_data
    |> Enum.reduce(graph, &entry(seed, &1, &2))
  end

  defp entry(seed, %DerivedSymbolData{} = data, graph) do
    case resolve_target(graph, seed.guid, data.guid_path) do
      {:ok, target_guid} ->
        Patch.apply_all(graph, patches(target_guid, data))

      {:error, reason} ->
        unresolved(graph, {:derived_data_target, seed.guid, data.guid_path, reason})
    end
  end

  defp resolve_target(graph, instance_guid, guid_path) do
    case Target.resolve(graph, instance_guid, guid_path) do
      {:ok, target_guid} ->
        {:ok, target_guid}

      {:error, _reason} ->
        guided_target(graph, instance_guid, guid_path) ||
          Target.resolve(graph, instance_guid, guid_path)
    end
  end

  defp guided_target(_graph, _current_guid, []), do: nil

  defp guided_target(graph, current_guid, guid_path) do
    Enum.reduce_while(guid_path, current_guid, fn source_guid, parent_guid ->
      case child_target(graph, parent_guid, source_guid) do
        nil -> {:halt, nil}
        child_guid -> {:cont, child_guid}
      end
    end)
    |> case do
      nil -> nil
      target_guid -> {:ok, target_guid}
    end
  end

  defp child_target(graph, parent_guid, source_guid) do
    exact_guid = GUID.append(parent_guid, source_guid)

    cond do
      Map.has_key?(graph.nodes, exact_guid) ->
        exact_guid

      source = Map.get(graph.nodes, source_guid) || Map.get(graph.seed_nodes, source_guid) ->
        descendant_by_name(graph, parent_guid, source)

      true ->
        nil
    end
  end

  defp descendant_by_name(graph, parent_guid, %{name: name, node_type: node_type}) do
    graph
    |> descendants(parent_guid)
    |> Enum.find(fn guid ->
      match?(%{name: ^name, node_type: ^node_type}, Map.get(graph.nodes, guid))
    end)
  end

  defp descendants(graph, guid) do
    graph.children
    |> Map.get(guid, [])
    |> Enum.flat_map(fn child_guid -> [child_guid | descendants(graph, child_guid)] end)
  end

  defp patches(target_guid, data) do
    []
    |> maybe_set(target_guid, :size, data.size)
    |> maybe_set(target_guid, :transform, data.transform)
  end

  defp maybe_set(patches, _target_guid, _field, nil), do: patches

  defp maybe_set(patches, target_guid, field, value) do
    [Patch.set(target_guid, field, value, source: :derived_symbol_data) | patches]
  end

  defp unresolved(%Graph{} = graph, item),
    do: %Graph{graph | unresolved: [item | graph.unresolved]}
end
