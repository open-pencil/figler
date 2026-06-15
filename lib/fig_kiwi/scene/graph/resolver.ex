defmodule FigKiwi.Scene.Graph.Resolver do
  @moduledoc """
  Pure Elixir resolver pipeline for `FigKiwi.Scene.Graph`.

  The resolver intentionally starts from structured seed nodes and ordinary
  Elixir maps so Figma semantics can be inspected, tested, and changed quickly.
  Rust remains the fast decoder/projector; this module owns the evolving
  override rules.
  """

  alias FigKiwi.Scene.Graph
  alias FigKiwi.Scene.Graph.ComponentProps
  alias FigKiwi.Scene.Graph.GUID
  alias FigKiwi.Scene.Graph.Patch
  alias FigKiwi.Scene.Graph.SeedNode
  alias FigKiwi.Scene.Graph.Target

  @doc """
  Builds the initial graph working set from seed nodes.
  """
  @spec from_seed([SeedNode.t()], keyword()) :: Graph.t()
  def from_seed(seed_nodes, opts \\ []) when is_list(seed_nodes) and is_list(opts) do
    nodes = Map.new(seed_nodes, &{&1.guid, SeedNode.to_node(&1)})
    seed_by_guid = Map.new(seed_nodes, &{&1.guid, &1})
    children = build_children(seed_nodes)
    roots = build_roots(seed_nodes)

    %Graph{
      resource: Keyword.fetch!(opts, :resource),
      source: Keyword.get(opts, :source),
      mode: :projected,
      stages: Keyword.get(opts, :stages, []),
      options: Keyword.get(opts, :options, []),
      seed_nodes: seed_by_guid,
      nodes: nodes,
      children: children,
      roots: roots,
      by_type: group_guids(seed_nodes, & &1.node_type),
      by_name: group_guids(seed_nodes, & &1.name),
      clone_index: %{},
      provenance: initial_provenance(seed_nodes),
      unresolved: [],
      stats: stats(seed_nodes, children, roots)
    }
  end

  @doc """
  Runs the requested resolver stages.

  Stage implementations are intentionally no-ops until their metadata extractors
  are wired. Keeping the dispatcher now makes each future semantic step small
  and independently testable.
  """
  @spec resolve(Graph.t()) :: Graph.t()
  def resolve(%Graph{} = graph) do
    Enum.reduce(graph.stages, graph, &run_stage/2)
  end

  defp run_stage(:populate_instances, graph), do: populate_instances(graph)
  defp run_stage(:symbol_overrides, graph), do: apply_symbol_overrides(graph)
  defp run_stage(:sync_overrides, graph), do: sync_overrides(graph)
  defp run_stage(:component_props, graph), do: apply_component_props(graph)
  defp run_stage(:sync_component_props, graph), do: sync_component_props(graph)
  defp run_stage(:derived_symbol_data, graph), do: apply_derived_symbol_data(graph)
  defp run_stage(:variables, graph), do: resolve_variables(graph)
  defp run_stage(stage, graph), do: add_unresolved(graph, {:unknown_stage, stage})

  defp populate_instances(graph) do
    graph.seed_nodes
    |> Map.values()
    |> Enum.reduce(graph, &populate_seed_instance/2)
    |> mark_stage(:populate_instances)
  end

  defp apply_symbol_overrides(graph) do
    graph.seed_nodes
    |> Map.values()
    |> Enum.reduce(graph, &apply_seed_symbol_overrides/2)
    |> mark_stage(:symbol_overrides)
  end

  defp sync_overrides(graph), do: mark_stage(graph, :sync_overrides)

  defp apply_component_props(graph) do
    graph.seed_nodes
    |> Map.values()
    |> Enum.reduce(graph, &ComponentProps.apply(&2, &1))
    |> mark_stage(:component_props)
  end

  defp sync_component_props(graph), do: mark_stage(graph, :sync_component_props)
  defp apply_derived_symbol_data(graph), do: mark_stage(graph, :derived_symbol_data)
  defp resolve_variables(graph), do: mark_stage(graph, :variables)

  defp apply_seed_symbol_overrides(%SeedNode{symbol_overrides: []}, graph), do: graph

  defp apply_seed_symbol_overrides(%SeedNode{} = seed, graph) do
    Enum.reduce(seed.symbol_overrides, graph, &apply_symbol_override(seed, &1, &2))
  end

  defp apply_symbol_override(seed, override, graph) do
    case Target.resolve(graph, seed.guid, override.guid_path) do
      {:ok, target_guid} ->
        graph
        |> Patch.apply_all(symbol_override_patches(target_guid, override.fields))

      {:error, reason} ->
        add_unresolved(graph, {:symbol_override_target, seed.guid, override.guid_path, reason})
    end
  end

  defp symbol_override_patches(target_guid, fields) do
    Enum.map(fields, fn {field, value} ->
      Patch.set(target_guid, field, value, source: :symbol_override)
    end)
  end

  defp populate_seed_instance(
         %SeedNode{node_type: "instance", symbol_id: component_guid} = instance,
         graph
       )
       when is_tuple(component_guid) do
    cond do
      Map.get(graph.children, instance.guid, []) != [] ->
        graph

      not Map.has_key?(graph.nodes, component_guid) ->
        add_unresolved(graph, {:instance_component, instance.guid, component_guid})

      true ->
        clone_children(graph, instance.guid, instance.guid, component_guid, component_guid)
    end
  end

  defp populate_seed_instance(_seed, graph), do: graph

  defp clone_children(graph, instance_guid, clone_parent_guid, source_parent_guid, component_guid) do
    graph.children
    |> Map.get(source_parent_guid, [])
    |> Enum.reduce(graph, fn source_child_guid, acc ->
      clone_subtree(acc, instance_guid, clone_parent_guid, source_child_guid, component_guid)
    end)
  end

  defp clone_subtree(graph, instance_guid, clone_parent_guid, source_guid, component_guid) do
    source_node = Map.fetch!(graph.nodes, source_guid)
    clone_guid = GUID.clone(instance_guid, source_guid)

    cloned_node = %{
      source_node
      | guid: GUID.format(clone_guid),
        parent_guid: GUID.format(clone_parent_guid)
    }

    source_seed = Map.get(graph.seed_nodes, source_guid)
    cloned_seed = clone_seed(source_seed, clone_guid, clone_parent_guid)

    graph
    |> put_clone_node(clone_guid, cloned_node, cloned_seed, instance_guid, source_guid)
    |> add_child(clone_parent_guid, clone_guid)
    |> put_clone_provenance(clone_guid, source_guid, instance_guid, component_guid)
    |> clone_children(instance_guid, clone_guid, source_guid, component_guid)
  end

  defp clone_seed(nil, _clone_guid, _clone_parent_guid), do: nil

  defp clone_seed(%SeedNode{} = seed, clone_guid, clone_parent_guid) do
    %SeedNode{seed | guid: clone_guid, parent_guid: clone_parent_guid, source: seed}
  end

  defp put_clone_node(
         %Graph{} = graph,
         clone_guid,
         cloned_node,
         cloned_seed,
         instance_guid,
         source_guid
       ) do
    %Graph{
      graph
      | nodes: Map.put(graph.nodes, clone_guid, cloned_node),
        seed_nodes: put_if_present(graph.seed_nodes, clone_guid, cloned_seed),
        by_type: append_group(graph.by_type, cloned_node.node_type, clone_guid),
        by_name: append_group(graph.by_name, cloned_node.name, clone_guid),
        clone_index: Map.put(graph.clone_index, {instance_guid, source_guid}, clone_guid)
    }
  end

  defp add_child(%Graph{} = graph, parent_guid, child_guid) do
    %Graph{
      graph
      | children: Map.update(graph.children, parent_guid, [child_guid], &(&1 ++ [child_guid]))
    }
  end

  defp put_clone_provenance(
         %Graph{} = graph,
         clone_guid,
         source_guid,
         instance_guid,
         component_guid
       ) do
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

  defp put_if_present(map, _key, nil), do: map
  defp put_if_present(map, key, value), do: Map.put(map, key, value)

  defp append_group(groups, nil, _guid), do: groups
  defp append_group(groups, "", _guid), do: groups
  defp append_group(groups, key, guid), do: Map.update(groups, key, [guid], &(&1 ++ [guid]))

  defp mark_stage(%Graph{} = graph, stage) do
    update_in(graph.stats[:resolved_stages], fn stages -> [stage | stages || []] end)
  end

  defp add_unresolved(%Graph{} = graph, item),
    do: %{graph | unresolved: [item | graph.unresolved]}

  defp build_children(seed_nodes) do
    seed_nodes
    |> Enum.reduce(%{}, fn
      %SeedNode{parent_guid: nil}, acc ->
        acc

      %SeedNode{parent_guid: parent_guid, guid: guid}, acc ->
        Map.update(acc, parent_guid, [guid], &[guid | &1])
    end)
    |> reverse_group_values()
  end

  defp build_roots(seed_nodes) do
    seed_nodes
    |> Enum.filter(&is_nil(&1.parent_guid))
    |> Enum.map(& &1.guid)
  end

  defp group_guids(seed_nodes, key_fun) do
    seed_nodes
    |> Enum.reduce(%{}, fn seed, acc ->
      case key_fun.(seed) do
        nil -> acc
        "" -> acc
        key -> Map.update(acc, key, [seed.guid], &[seed.guid | &1])
      end
    end)
    |> reverse_group_values()
  end

  defp reverse_group_values(groups) do
    Map.new(groups, fn {key, values} -> {key, Enum.reverse(values)} end)
  end

  defp initial_provenance(seed_nodes) do
    Map.new(seed_nodes, fn seed ->
      {seed.guid,
       %{
         source: :projected_index,
         source_guid: seed.guid,
         applied: [],
         unresolved: []
       }}
    end)
  end

  defp stats(seed_nodes, children, roots) do
    %{
      resolver: :elixir,
      node_count: length(seed_nodes),
      parented_count:
        Enum.reduce(children, 0, fn {_parent, guids}, count -> count + length(guids) end),
      root_count: length(roots),
      resolved_stages: []
    }
  end
end
