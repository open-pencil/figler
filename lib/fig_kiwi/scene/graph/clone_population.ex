defmodule FigKiwi.Scene.Graph.ClonePopulation do
  @moduledoc """
  Populates instance nodes by cloning their source component subtrees.
  """

  alias FigKiwi.Scene.Graph
  alias FigKiwi.Scene.Graph.GUID
  alias FigKiwi.Scene.Graph.Nodes
  alias FigKiwi.Scene.Graph.Provenance
  alias FigKiwi.Scene.Graph.SeedNode

  @doc """
  Populates a single source instance seed into the graph.
  """
  @spec apply(Graph.t(), SeedNode.t()) :: Graph.t()
  def apply(
        %Graph{} = graph,
        %SeedNode{node_type: "instance", symbol_id: component_guid} = instance
      )
      when is_tuple(component_guid) do
    cond do
      instance.visible == false ->
        graph

      Map.get(graph.children, instance.guid, []) != [] ->
        graph

      not Map.has_key?(graph.nodes, component_guid) ->
        unresolved(graph, {:instance_component, instance.guid, component_guid})

      true ->
        clone_children(
          graph,
          instance.guid,
          instance.guid,
          component_guid,
          component_guid,
          {1.0, 1.0}
        )
    end
  end

  def apply(%Graph{} = graph, _seed), do: graph

  defp clone_children(
         graph,
         instance_guid,
         clone_parent_guid,
         source_parent_guid,
         component_guid,
         scale
       ) do
    graph.children
    |> Map.get(source_parent_guid, [])
    |> Enum.reduce(graph, fn source_child_guid, acc ->
      clone_subtree(
        acc,
        instance_guid,
        clone_parent_guid,
        source_child_guid,
        component_guid,
        scale
      )
    end)
  end

  defp clone_subtree(graph, instance_guid, clone_parent_guid, source_guid, component_guid, scale) do
    source_node = Map.fetch!(graph.nodes, source_guid)
    clone_guid = GUID.append(clone_parent_guid, source_guid)

    cloned_node = %{
      source_node
      | guid: GUID.format(clone_guid),
        parent_guid: GUID.format(clone_parent_guid),
        transform: scale_transform(source_node.transform, scale)
    }

    source_seed = Map.get(graph.seed_nodes, source_guid)
    cloned_seed = SeedNode.clone(source_seed, clone_guid, clone_parent_guid)

    graph
    |> put_clone_node(clone_guid, cloned_node, cloned_seed, instance_guid, source_guid)
    |> Nodes.child(clone_parent_guid, clone_guid)
    |> Provenance.put_clone(clone_guid, source_guid, instance_guid, component_guid)
    |> clone_children(instance_guid, clone_guid, source_guid, component_guid, scale)
    |> populate_nested_clone(source_seed, instance_guid, clone_guid)
  end

  defp populate_nested_clone(
         graph,
         %SeedNode{node_type: "instance", symbol_id: nested_component_guid} = source_seed,
         root_instance_guid,
         clone_guid
       )
       when is_tuple(nested_component_guid) do
    if source_seed.visible != false and Map.get(graph.children, clone_guid, []) == [] and
         Map.has_key?(graph.nodes, nested_component_guid) do
      scale = nested_instance_scale(graph, source_seed, nested_component_guid)

      clone_children(
        graph,
        root_instance_guid,
        clone_guid,
        nested_component_guid,
        nested_component_guid,
        scale
      )
    else
      graph
    end
  end

  defp populate_nested_clone(graph, _source_seed, _root_instance_guid, _clone_guid), do: graph

  defp nested_instance_scale(graph, source_seed, component_guid) do
    case Map.get(graph.children, component_guid, []) do
      [_single_child] -> scale(source_seed, Map.get(graph.nodes, component_guid))
      _children -> {1.0, 1.0}
    end
  end

  defp scale(source, target) do
    with %{x: sx, y: sy} <- size(source),
         %{x: tx, y: ty} <- size(target),
         true <- usable_dimension?(tx),
         true <- usable_dimension?(ty) do
      {sx / tx, sy / ty}
    else
      _value -> {1.0, 1.0}
    end
  end

  defp size(%{size: size}), do: size
  defp size(_node), do: nil

  defp usable_dimension?(value), do: value not in [nil, 0]

  defp scale_transform(nil, _scale), do: nil

  defp scale_transform(transform, scale) do
    transform
    |> scaled_offset(:m02, elem(scale, 0))
    |> scaled_offset(:m12, elem(scale, 1))
  end

  defp scaled_offset(transform, key, scale) do
    Map.update(transform, key, nil, fn
      nil -> nil
      value -> value * scale
    end)
  end

  defp put_clone_node(
         %Graph{} = graph,
         clone_guid,
         cloned_node,
         cloned_seed,
         instance_guid,
         source_guid
       ) do
    %Graph{} = graph = Nodes.put(graph, clone_guid, cloned_node, cloned_seed)

    %Graph{
      graph
      | clone_index:
          Map.put(graph.clone_index, {GUID.root(instance_guid), source_guid}, clone_guid)
    }
  end

  defp unresolved(%Graph{} = graph, item),
    do: %Graph{graph | unresolved: [item | graph.unresolved]}
end
