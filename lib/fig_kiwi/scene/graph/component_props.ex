defmodule FigKiwi.Scene.Graph.ComponentProps do
  @moduledoc """
  Component property assignment support for the graph resolver.
  """

  alias FigKiwi.Scene.Graph
  alias FigKiwi.Scene.Graph.GUID
  alias FigKiwi.Scene.Graph.Patch
  alias FigKiwi.Scene.Graph.SeedNode

  @doc """
  Applies component property assignments from an instance seed.
  """
  @spec apply(Graph.t(), SeedNode.t()) :: Graph.t()
  def apply(%Graph{} = graph, %SeedNode{component_prop_assignments: []}), do: graph

  def apply(%Graph{} = graph, %SeedNode{} = instance) do
    instance.component_prop_assignments
    |> Enum.reduce(graph, &apply_assignment(instance, &1, &2))
  end

  @doc """
  Finds the source node and field referenced by a component property definition.
  """
  @spec ref(Graph.t(), GUID.figma_guid()) :: {GUID.graph_guid(), atom()} | nil
  def ref(%Graph{} = graph, def_id) do
    graph.seed_nodes
    |> Map.values()
    |> Enum.find_value(fn seed ->
      seed.component_prop_refs
      |> Enum.find(&(&1.def_id == def_id))
      |> case do
        nil -> nil
        prop_ref -> field(prop_ref.field) && {seed.guid, field(prop_ref.field)}
      end
    end)
  end

  defp apply_assignment(instance, assignment, graph) do
    with {source_guid, field} <- ref(graph, assignment.def_id),
         {:ok, target_guid} <- target(graph, instance.guid, source_guid),
         {:ok, value} <- value(field, assignment.value) do
      Patch.apply_all(graph, patch(target_guid, field, value))
    else
      nil ->
        unresolved(graph, {:component_prop_ref, instance.guid, assignment.def_id})

      {:error, reason} ->
        unresolved(graph, {:component_prop_assignment, instance.guid, assignment.def_id, reason})
    end
  end

  defp target(graph, instance_guid, source_guid) do
    cond do
      clone_guid = Map.get(graph.clone_index, {GUID.root(instance_guid), source_guid}) ->
        {:ok, clone_guid}

      Map.has_key?(graph.nodes, source_guid) ->
        {:ok, source_guid}

      true ->
        {:error, :missing_target}
    end
  end

  defp field(:visible), do: :visible
  defp field(:text_data), do: :text
  defp field(:overridden_symbol_id), do: :component_guid
  defp field("VISIBLE"), do: :visible
  defp field("TEXT"), do: :text
  defp field("TEXT_DATA"), do: :text
  defp field("OVERRIDDEN_SYMBOL_ID"), do: :component_guid
  defp field(_field), do: nil

  defp patch(target_guid, :component_guid, value),
    do: Patch.swap(target_guid, value, source: :component_prop)

  defp patch(target_guid, field, value),
    do: Patch.set(target_guid, field, value, source: :component_prop)

  defp value(:visible, {:bool, value}), do: {:ok, value}
  defp value(:text, {:text, value}), do: {:ok, value}
  defp value(:component_guid, {:guid, value}), do: {:ok, value}
  defp value(_field, _value), do: {:error, :unsupported_value}

  defp unresolved(%Graph{} = graph, item),
    do: %Graph{graph | unresolved: [item | graph.unresolved]}
end
