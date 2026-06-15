defmodule FigKiwi.Scene.Graph.Swap do
  @moduledoc """
  Materializes instance component swaps.
  """

  alias FigKiwi.Scene.Graph
  alias FigKiwi.Scene.Graph.GUID
  alias FigKiwi.Scene.Graph.Nodes
  alias FigKiwi.Scene.Graph.SeedNode

  @doc """
  Replaces an instance's cloned children with children cloned from `component_guid`.
  """
  @spec run(Graph.t(), GUID.graph_guid(), GUID.figma_guid()) :: Graph.t()
  def run(%Graph{} = graph, target_guid, component_guid) do
    graph
    |> clear(target_guid)
    |> fill(target_guid, component_guid)
  end

  @doc """
  Removes current children under an instance target.
  """
  @spec clear(Graph.t(), GUID.graph_guid()) :: Graph.t()
  def clear(%Graph{} = graph, target_guid) do
    graph.children
    |> Map.get(target_guid, [])
    |> Enum.reduce(graph, &Nodes.remove(&2, &1))
  end

  @doc """
  Clones component children under an instance target.
  """
  @spec fill(Graph.t(), GUID.graph_guid(), GUID.figma_guid()) :: Graph.t()
  def fill(%Graph{} = graph, target_guid, component_guid) do
    graph.children
    |> Map.get(component_guid, [])
    |> Enum.reduce(graph, fn source_child_guid, acc ->
      clone(acc, target_guid, target_guid, source_child_guid, component_guid)
    end)
  end

  defp clone(graph, instance_guid, parent_guid, source_guid, component_guid) do
    source_node = Map.fetch!(graph.nodes, source_guid)
    clone_guid = GUID.clone(instance_guid, source_guid)

    cloned_node = %{
      source_node
      | guid: GUID.format(clone_guid),
        parent_guid: GUID.format(parent_guid)
    }

    cloned_seed =
      graph.seed_nodes
      |> Map.get(source_guid)
      |> SeedNode.clone(clone_guid, parent_guid)

    graph
    |> Nodes.put(clone_guid, cloned_node, cloned_seed)
    |> Nodes.child(parent_guid, clone_guid)
    |> put_index(instance_guid, source_guid, clone_guid)
    |> put_provenance(clone_guid, source_guid, instance_guid, component_guid)
    |> fill_child(instance_guid, clone_guid, source_guid, component_guid)
  end

  defp fill_child(graph, instance_guid, parent_guid, source_guid, component_guid) do
    graph.children
    |> Map.get(source_guid, [])
    |> Enum.reduce(graph, fn child_guid, acc ->
      clone(acc, instance_guid, parent_guid, child_guid, component_guid)
    end)
  end

  defp put_index(%Graph{} = graph, instance_guid, source_guid, clone_guid) do
    %Graph{
      graph
      | clone_index: Map.put(graph.clone_index, {instance_guid, source_guid}, clone_guid)
    }
  end

  defp put_provenance(%Graph{} = graph, clone_guid, source_guid, instance_guid, component_guid) do
    provenance = %{
      source: :instance_clone,
      source_guid: source_guid,
      instance_guid: instance_guid,
      component_guid: component_guid,
      applied: [],
      unresolved: []
    }

    %Graph{graph | provenance: Map.put(graph.provenance, clone_guid, provenance)}
  end
end
