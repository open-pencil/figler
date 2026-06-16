defmodule FigKiwi.Scene.Graph.Swap do
  @moduledoc """
  Materializes instance component swaps.
  """

  alias FigKiwi.Scene.Graph
  alias FigKiwi.Scene.Graph.GUID
  alias FigKiwi.Scene.Graph.Nodes
  alias FigKiwi.Scene.Graph.Patch
  alias FigKiwi.Scene.Graph.Provenance
  alias FigKiwi.Scene.Graph.SeedNode

  @doc """
  Replaces an instance's cloned children with children cloned from `component_guid`.
  """
  @spec run(Graph.t(), GUID.graph_guid(), GUID.figma_guid()) :: Graph.t()
  def run(%Graph{} = graph, target_guid, component_guid) do
    scale = scale(graph, target_guid, component_guid)

    graph
    |> clear(target_guid)
    |> update_target(target_guid, component_guid)
    |> fill(target_guid, component_guid, scale)
  end

  defp update_target(%Graph{} = graph, target_guid, component_guid) do
    case Map.fetch(graph.nodes, component_guid) do
      {:ok, component} ->
        patches =
          []
          |> maybe_name_patch(target_guid, component.name)
          |> maybe_visible_patch(target_guid, component.visible)

        Patch.apply_all(graph, patches)

      _other ->
        graph
    end
  end

  defp maybe_name_patch(patches, _target_guid, nil), do: patches

  defp maybe_name_patch(patches, target_guid, name) do
    if rename_component?(name),
      do: [Patch.set(target_guid, :name, name, source: :component_swap) | patches],
      else: patches
  end

  defp maybe_visible_patch(patches, _target_guid, nil), do: patches

  defp maybe_visible_patch(patches, target_guid, visible) do
    [Patch.set(target_guid, :visible, visible, source: :component_swap) | patches]
  end

  defp rename_component?(name), do: not String.contains?(name, "=")

  @doc """
  Removes current children under an instance target.
  """
  @spec clear(Graph.t(), GUID.graph_guid()) :: Graph.t()
  def clear(%Graph{} = graph, target_guid) do
    Nodes.clear_children(graph, target_guid, indexes: false)
  end

  @doc """
  Clones component children under an instance target.
  """
  @spec fill(Graph.t(), GUID.graph_guid(), GUID.figma_guid(), {number(), number()}) :: Graph.t()
  def fill(%Graph{} = graph, target_guid, component_guid, scale \\ {1.0, 1.0}) do
    graph.children
    |> Map.get(component_guid, [])
    |> Enum.reduce(graph, fn source_child_guid, acc ->
      clone(acc, target_guid, target_guid, source_child_guid, component_guid, scale)
    end)
  end

  defp clone(graph, instance_guid, parent_guid, source_guid, component_guid, scale) do
    source_node = Map.fetch!(graph.nodes, source_guid)
    clone_guid = GUID.append(parent_guid, source_guid)

    cloned_node = %{
      source_node
      | guid: GUID.format(clone_guid),
        parent_guid: GUID.format(parent_guid),
        transform: scale_transform(source_node.transform, scale)
    }

    cloned_seed =
      graph.seed_nodes
      |> Map.get(source_guid)
      |> SeedNode.clone(clone_guid, parent_guid)

    graph
    |> Nodes.put(clone_guid, cloned_node, cloned_seed)
    |> Nodes.child(parent_guid, clone_guid)
    |> put_index(GUID.root(instance_guid), source_guid, clone_guid)
    |> Provenance.put_clone(clone_guid, source_guid, instance_guid, component_guid)
    |> fill_child(instance_guid, clone_guid, source_guid, component_guid, scale)
    |> fill_nested_instance(cloned_seed, clone_guid)
  end

  defp fill_child(graph, instance_guid, parent_guid, source_guid, component_guid, scale) do
    graph.children
    |> Map.get(source_guid, [])
    |> Enum.reduce(graph, fn child_guid, acc ->
      clone(acc, instance_guid, parent_guid, child_guid, component_guid, scale)
    end)
  end

  defp fill_nested_instance(
         graph,
         %SeedNode{component_guid: nested_component_guid, visible: visible},
         clone_guid
       )
       when is_tuple(nested_component_guid) do
    if visible != false and Map.get(graph.children, clone_guid, []) == [] and
         Map.has_key?(graph.nodes, nested_component_guid) do
      fill(
        graph,
        clone_guid,
        nested_component_guid,
        nested_scale(graph, clone_guid, nested_component_guid)
      )
    else
      graph
    end
  end

  defp fill_nested_instance(graph, _seed, _clone_guid), do: graph

  defp nested_scale(graph, target_guid, component_guid) do
    case Map.get(graph.children, component_guid, []) do
      [_single_child] -> scale(graph, target_guid, component_guid)
      _children -> {1.0, 1.0}
    end
  end

  defp scale(%Graph{} = graph, target_guid, component_guid) do
    target_size = graph.nodes |> Map.get(target_guid) |> size()
    component_size = graph.nodes |> Map.get(component_guid) |> size()

    case {target_size, component_size} do
      {%{x: tx, y: ty}, %{x: cx, y: cy}} when cx not in [nil, 0] and cy not in [nil, 0] ->
        {tx / cx, ty / cy}

      _other ->
        {1.0, 1.0}
    end
  end

  defp size(%{size: size}), do: size
  defp size(_node), do: nil

  defp scale_transform(nil, _scale), do: nil

  defp scale_transform(transform, {scale_x, scale_y}) do
    transform
    |> Map.update(:m02, nil, &scale_value(&1, scale_x))
    |> Map.update(:m12, nil, &scale_value(&1, scale_y))
  end

  defp scale_value(nil, _scale), do: nil
  defp scale_value(value, scale), do: value * scale

  defp put_index(%Graph{} = graph, instance_guid, source_guid, clone_guid) do
    %Graph{
      graph
      | clone_index: Map.put(graph.clone_index, {instance_guid, source_guid}, clone_guid),
        clone_source_index:
          Map.put(graph.clone_source_index, {instance_guid, source_leaf(source_guid)}, clone_guid)
    }
  end

  defp source_leaf({:clone, _root_guid, source_path}), do: List.last(source_path)
  defp source_leaf(source_guid), do: source_guid
end
