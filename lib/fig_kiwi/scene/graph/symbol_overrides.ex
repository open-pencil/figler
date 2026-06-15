defmodule FigKiwi.Scene.Graph.SymbolOverrides do
  @moduledoc """
  Applies symbol override swaps, carried component props, and field patches.
  """

  alias FigKiwi.Scene.Graph
  alias FigKiwi.Scene.Graph.ComponentProps
  alias FigKiwi.Scene.Graph.Patch
  alias FigKiwi.Scene.Graph.SeedNode
  alias FigKiwi.Scene.Graph.Target

  @doc """
  Applies symbol overrides from source instance seeds.
  """
  @spec apply(Graph.t(), [SeedNode.t()]) :: Graph.t()
  def apply(%Graph{} = graph, seeds) when is_list(seeds) do
    graph
    |> reduce(seeds, &swap_from/2)
    |> reduce(seeds, &component_props_from/2)
    |> reduce(seeds, &patch_from/2)
  end

  defp swap_from(%SeedNode{symbol_overrides: []}, graph), do: graph

  defp swap_from(%SeedNode{} = seed, graph) do
    seed.symbol_overrides
    |> Enum.filter(& &1.overridden_symbol_id)
    |> Enum.reduce(graph, &swap(seed, &1, &2))
  end

  defp component_props_from(%SeedNode{symbol_overrides: []}, graph), do: graph

  defp component_props_from(%SeedNode{} = seed, graph) do
    seed.symbol_overrides
    |> Enum.reject(&(&1.component_prop_assignments == []))
    |> Enum.reduce(graph, &component_props(seed, &1, &2))
  end

  defp patch_from(%SeedNode{symbol_overrides: []}, graph), do: graph

  defp patch_from(%SeedNode{} = seed, graph) do
    seed.symbol_overrides
    |> Enum.reject(&(&1.fields == %{}))
    |> Enum.reduce(graph, &patch(seed, &1, &2))
  end

  defp swap(seed, override, graph) do
    case Target.resolve(graph, seed.guid, override.guid_path) do
      {:ok, target_guid} ->
        Patch.apply_all(
          graph,
          Patch.swap(target_guid, override.overridden_symbol_id, source: :symbol_override)
        )

      {:error, reason} ->
        unresolved(graph, {:symbol_override_target, seed.guid, override.guid_path, reason})
    end
  end

  defp component_props(seed, override, graph) do
    case Target.resolve(graph, seed.guid, override.guid_path) do
      {:ok, target_guid} ->
        ComponentProps.apply_assignments(graph, target_guid, override.component_prop_assignments)

      {:error, reason} ->
        unresolved(graph, {:symbol_override_target, seed.guid, override.guid_path, reason})
    end
  end

  defp patch(seed, override, graph) do
    case Target.resolve(graph, seed.guid, override.guid_path) do
      {:ok, target_guid} ->
        Patch.apply_all(graph, field_patches(target_guid, override.fields))

      {:error, reason} ->
        unresolved(graph, {:symbol_override_target, seed.guid, override.guid_path, reason})
    end
  end

  defp field_patches(target_guid, fields) do
    Enum.map(fields, fn {field, value} ->
      Patch.set(target_guid, field, value, source: :symbol_override)
    end)
  end

  defp reduce(graph, values, fun), do: Enum.reduce(values, graph, fun)

  defp unresolved(%Graph{} = graph, item),
    do: %Graph{graph | unresolved: [item | graph.unresolved]}
end
