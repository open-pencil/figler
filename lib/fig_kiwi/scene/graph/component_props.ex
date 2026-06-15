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
    graph
    |> reduce(instance, &swap?/1)
    |> reduce(instance, &(not swap?(&1)))
  end

  @doc """
  Finds the source node and field referenced by a component property definition.
  """
  @spec ref(Graph.t(), GUID.figma_guid()) :: {GUID.graph_guid(), atom()} | nil
  def ref(%Graph{} = graph, def_id) do
    Map.get(graph.component_prop_refs, def_id)
  end

  defp reduce(graph, instance, predicate) do
    instance.component_prop_assignments
    |> Enum.filter(predicate)
    |> Enum.reduce(graph, &apply_assignment(instance, &1, &2))
  end

  defp swap?(assignment), do: match?({:guid, _guid}, assignment.value)

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
      clone_guid = nested_clone(graph, instance_guid, source_guid) ->
        {:ok, clone_guid}

      clone_guid = Map.get(graph.clone_index, {GUID.root(instance_guid), source_guid}) ->
        {:ok, clone_guid}

      Map.has_key?(graph.nodes, source_guid) ->
        {:ok, source_guid}

      true ->
        {:error, :missing_target}
    end
  end

  defp nested_clone(graph, {:clone, _root, _path} = instance_guid, source_guid) do
    clone_guid = GUID.append(instance_guid, source_guid)
    if Map.has_key?(graph.nodes, clone_guid), do: clone_guid
  end

  defp nested_clone(_graph, _instance_guid, _source_guid), do: nil

  @doc false
  def field(:visible), do: :visible
  def field(:text_data), do: :text
  def field(:overridden_symbol_id), do: :component_guid
  def field("VISIBLE"), do: :visible
  def field("TEXT"), do: :text
  def field("TEXT_DATA"), do: :text
  def field("OVERRIDDEN_SYMBOL_ID"), do: :component_guid
  def field(_field), do: nil

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
