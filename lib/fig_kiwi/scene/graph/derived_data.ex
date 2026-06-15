defmodule FigKiwi.Scene.Graph.DerivedData do
  @moduledoc """
  Applies Figma-derived symbol data to populated graph nodes.
  """

  alias FigKiwi.Scene.Graph
  alias FigKiwi.Scene.Graph.DerivedSymbolData
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
    case Target.resolve(graph, seed.guid, data.guid_path) do
      {:ok, target_guid} ->
        Patch.apply_all(graph, patches(target_guid, data))

      {:error, reason} ->
        unresolved(graph, {:derived_data_target, seed.guid, data.guid_path, reason})
    end
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
