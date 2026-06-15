defmodule FigKiwi.Scene.Graph.ComponentProps do
  @moduledoc """
  Component property assignment support for the graph resolver.
  """

  import Kernel, except: [apply: 2]

  alias FigKiwi.Scene.Graph
  alias FigKiwi.Scene.Graph.GUID
  alias FigKiwi.Scene.Graph.Patch
  alias FigKiwi.Scene.Graph.SeedNode

  @doc false
  def index(seed_nodes) do
    Enum.reduce(seed_nodes, %{}, &add_refs/2)
  end

  @doc """
  Applies component property assignments from all instance seeds in the graph.
  """
  @spec apply_all(Graph.t()) :: Graph.t()
  def apply_all(%Graph{} = graph) do
    graph
    |> instances()
    |> Enum.reduce(graph, &apply(&2, &1))
  end

  @doc """
  Applies component property assignments from an instance seed.
  """
  @spec apply(Graph.t(), SeedNode.t()) :: Graph.t()
  def apply(%Graph{} = graph, %SeedNode{component_prop_assignments: []}), do: graph

  def apply(%Graph{} = graph, %SeedNode{} = instance) do
    apply_assignments(graph, instance.guid, instance.component_prop_assignments)
  end

  @doc false
  def apply_assignments(%Graph{} = graph, instance_guid, assignments) do
    graph
    |> reduce(instance_guid, assignments, &swap?/1)
    |> reduce(instance_guid, assignments, &(not swap?(&1)))
  end

  @doc """
  Finds the source node and field referenced by a component property definition.
  """
  @spec ref(Graph.t(), GUID.figma_guid()) :: {GUID.graph_guid(), atom()} | nil
  def ref(%Graph{} = graph, def_id) do
    graph
    |> refs(def_id)
    |> List.first()
  end

  defp add_refs(seed, refs) do
    Enum.reduce(seed.component_prop_refs, refs, &add_ref(seed, &1, &2))
  end

  defp add_ref(seed, prop_ref, refs) do
    with def_id when not is_nil(def_id) <- prop_ref.def_id,
         field when not is_nil(field) <- field(prop_ref.field) do
      Map.update(refs, def_id, [{seed.guid, field}], &[{seed.guid, field} | &1])
    else
      _value -> refs
    end
  end

  defp instances(graph) do
    graph.seed_nodes
    |> Enum.flat_map(fn
      {_guid, %{node_type: "instance", component_prop_assignments: assignments} = seed}
      when assignments != [] ->
        [seed]

      _entry ->
        []
    end)
  end

  defp reduce(graph, instance_guid, assignments, predicate) do
    assignments
    |> Enum.filter(predicate)
    |> Enum.reduce(graph, &apply_assignment(instance_guid, &1, &2))
  end

  defp swap?(assignment), do: match?({:guid, _guid}, assignment.value)

  defp apply_assignment(instance_guid, assignment, graph) do
    case refs(graph, assignment.def_id) do
      [] ->
        unresolved(graph, {:component_prop_ref, instance_guid, assignment.def_id})

      refs ->
        Enum.reduce(refs, graph, &apply_ref(instance_guid, assignment, &1, &2))
    end
  end

  defp refs(%Graph{} = graph, def_id) do
    graph.component_prop_refs
    |> Map.get(def_id, [])
    |> List.wrap()
  end

  defp apply_ref(instance_guid, assignment, {source_guid, field}, graph) do
    with source_guid <- normalize_guid(source_guid),
         {:ok, target_guid} <- target(graph, instance_guid, source_guid),
         {:ok, value} <- value(field, assignment.value) do
      Patch.apply_all(graph, patches(graph, target_guid, field, value))
    else
      {:error, reason} ->
        unresolved(graph, {:component_prop_assignment, instance_guid, assignment.def_id, reason})
    end
  end

  defp normalize_guid(%{guid: guid}), do: GUID.parse!(guid)
  defp normalize_guid(guid), do: guid

  defp target(graph, instance_guid, source_guid) do
    cond do
      clone_guid = nested_clone(graph, instance_guid, source_guid) ->
        {:ok, normalize_guid(clone_guid)}

      clone_guid = descendant_by_name(graph, instance_guid, source_guid) ->
        {:ok, normalize_guid(clone_guid)}

      clone_guid = Map.get(graph.clone_index, {GUID.root(instance_guid), source_guid}) ->
        {:ok, normalize_guid(clone_guid)}

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

  defp descendant_by_name(graph, instance_guid, source_guid) do
    case Map.get(graph.nodes, source_guid) || Map.get(graph.seed_nodes, source_guid) do
      %{name: name, node_type: node_type} when is_binary(name) ->
        graph
        |> descendants(instance_guid)
        |> Enum.find(&same_name_and_type?(graph, &1, name, node_type))

      _node ->
        nil
    end
  end

  defp same_name_and_type?(graph, guid, name, node_type) do
    match?(%{name: ^name, node_type: ^node_type}, Map.get(graph.nodes, guid))
  end

  defp descendants(graph, guid) do
    graph.children
    |> Map.get(guid, [])
    |> Enum.flat_map(fn child_guid -> [child_guid | descendants(graph, child_guid)] end)
  end

  @doc false
  def field(:visible), do: :visible
  def field(:text_data), do: :text
  def field(:overridden_symbol_id), do: :component_guid
  def field("VISIBLE"), do: :visible
  def field("TEXT"), do: :text
  def field("TEXT_DATA"), do: :text
  def field("OVERRIDDEN_SYMBOL_ID"), do: :component_guid
  def field(_field), do: nil

  defp patches(_graph, target_guid, :component_guid, value),
    do: Patch.swap(target_guid, value, source: :component_prop)

  defp patches(graph, target_guid, :visible, false) do
    [Patch.set(target_guid, :visible, false, source: :component_prop)] ++
      source_transform_patch(graph, target_guid)
  end

  defp patches(_graph, target_guid, field, value),
    do: Patch.set(target_guid, field, value, source: :component_prop)

  defp source_transform_patch(graph, target_guid) do
    case Map.get(graph.seed_nodes, target_guid) do
      %{transform: transform} when not is_nil(transform) ->
        [Patch.set(target_guid, :transform, transform, source: :component_prop)]

      _seed ->
        []
    end
  end

  defp value(:visible, {:bool, value}), do: {:ok, value}
  defp value(:text, {:text, value}), do: {:ok, value}
  defp value(:component_guid, {:guid, value}), do: {:ok, value}
  defp value(_field, _value), do: {:error, :unsupported_value}

  defp unresolved(%Graph{} = graph, item),
    do: %Graph{graph | unresolved: [item | graph.unresolved]}
end
