defmodule FigKiwi.Scene.Graph.Resolver do
  @moduledoc """
  Pure Elixir resolver pipeline for `FigKiwi.Scene.Graph`.

  The resolver intentionally starts from structured seed nodes and ordinary
  Elixir maps so Figma semantics can be inspected, tested, and changed quickly.
  Rust remains the fast decoder/projector; this module owns the evolving
  override rules.
  """

  alias FigKiwi.Scene.Graph
  alias FigKiwi.Scene.Graph.ClonePopulation
  alias FigKiwi.Scene.Graph.ComponentProps
  alias FigKiwi.Scene.Graph.DerivedData
  alias FigKiwi.Scene.Graph.GUID
  alias FigKiwi.Scene.Graph.Patch
  alias FigKiwi.Scene.Graph.Provenance
  alias FigKiwi.Scene.Graph.SeedNode
  alias FigKiwi.Scene.Graph.StackLayout
  alias FigKiwi.Scene.Graph.Target

  @doc """
  Builds the initial graph working set from seed nodes.
  """
  @spec from_seed([SeedNode.t()], keyword()) :: Graph.t()
  def from_seed(seed_nodes, opts \\ []) when is_list(seed_nodes) and is_list(opts) do
    options = Keyword.get(opts, :options, [])
    seed_nodes = materialized_seed_nodes(seed_nodes, options)
    nodes = Map.new(seed_nodes, &{&1.guid, SeedNode.to_node(&1)})
    seed_by_guid = Map.new(seed_nodes, &{&1.guid, &1})
    children = build_children(seed_nodes)
    roots = build_roots(seed_nodes)

    %Graph{
      resource: Keyword.fetch!(opts, :resource),
      source: Keyword.get(opts, :source),
      mode: :projected,
      stages: Keyword.get(opts, :stages, []),
      options: options,
      seed_nodes: seed_by_guid,
      nodes: nodes,
      children: children,
      roots: roots,
      by_type: group_guids(seed_nodes, & &1.node_type),
      by_name: group_guids(seed_nodes, & &1.name),
      clone_index: %{},
      component_prop_refs: component_prop_refs(seed_nodes),
      provenance: Provenance.initial(seed_nodes),
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
  defp run_stage(:stack_layout, graph), do: apply_stack_layout(graph)
  defp run_stage(:variables, graph), do: resolve_variables(graph)
  defp run_stage(stage, graph), do: add_unresolved(graph, {:unknown_stage, stage})

  defp populate_instances(graph) do
    graph
    |> source_instances()
    |> Enum.reduce(graph, &ClonePopulation.apply(&2, &1))
    |> mark_stage(:populate_instances)
  end

  defp apply_symbol_overrides(graph) do
    seeds = source_instances(graph)

    graph
    |> reduce(seeds, &swap_from/2)
    |> reduce(seeds, &component_props_from/2)
    |> reduce(seeds, &patch_from/2)
    |> mark_stage(:symbol_overrides)
  end

  defp sync_overrides(graph), do: mark_stage(graph, :sync_overrides)

  defp apply_component_props(graph) do
    graph
    |> component_prop_instances()
    |> Enum.reduce(graph, &ComponentProps.apply(&2, &1))
    |> mark_stage(:component_props)
  end

  defp sync_component_props(graph), do: mark_stage(graph, :sync_component_props)

  defp apply_derived_symbol_data(graph) do
    graph
    |> source_instances()
    |> Enum.reduce(graph, &DerivedData.apply(&2, &1))
    |> mark_stage(:derived_symbol_data)
  end

  defp apply_stack_layout(graph) do
    graph
    |> StackLayout.apply()
    |> mark_stage(:stack_layout)
  end

  defp resolve_variables(graph), do: mark_stage(graph, :variables)

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
        add_unresolved(graph, {:symbol_override_target, seed.guid, override.guid_path, reason})
    end
  end

  defp component_props(seed, override, graph) do
    case Target.resolve(graph, seed.guid, override.guid_path) do
      {:ok, target_guid} ->
        ComponentProps.apply_assignments(graph, target_guid, override.component_prop_assignments)

      {:error, reason} ->
        add_unresolved(graph, {:symbol_override_target, seed.guid, override.guid_path, reason})
    end
  end

  defp patch(seed, override, graph) do
    case Target.resolve(graph, seed.guid, override.guid_path) do
      {:ok, target_guid} ->
        Patch.apply_all(graph, field_patches(target_guid, override.fields))

      {:error, reason} ->
        add_unresolved(graph, {:symbol_override_target, seed.guid, override.guid_path, reason})
    end
  end

  defp field_patches(target_guid, fields) do
    Enum.map(fields, fn {field, value} ->
      Patch.set(target_guid, field, value, source: :symbol_override)
    end)
  end

  defp reduce(graph, values, fun), do: Enum.reduce(values, graph, fun)

  defp component_prop_instances(graph) do
    graph.seed_nodes
    |> Enum.flat_map(fn
      {_guid, %{node_type: "instance", component_prop_assignments: assignments} = seed}
      when assignments != [] ->
        [seed]

      _entry ->
        []
    end)
  end

  defp source_instances(graph) do
    focus = focus_set(graph)

    Enum.flat_map(graph.seed_nodes, fn
      {guid, %{origin: :source, node_type: "instance"} = seed} ->
        if (is_nil(focus) or MapSet.member?(focus, guid)) and
             not opaque_definition_instance?(graph, guid),
           do: [seed],
           else: []

      _entry ->
        []
    end)
  end

  defp opaque_definition_instance?(graph, guid) do
    graph
    |> definition_symbol_ancestors(guid)
    |> Enum.any?(&(not focused_source?(graph, &1)))
  end

  defp definition_symbol_ancestors(graph, guid) do
    case Map.get(graph.nodes, guid) do
      %{parent_guid: parent_guid} when is_binary(parent_guid) ->
        graph
        |> ancestor_nodes(parent_guid)
        |> Enum.filter(&(&1.node_type == "symbol"))
        |> Enum.map(&GUID.parse!(&1.guid))

      _node ->
        []
    end
  end

  defp focused_source?(graph, guid) do
    guid in Keyword.get(graph.options, :focus, [])
  end

  defp ancestor_nodes(graph, parent_guid) do
    parent_guid
    |> GUID.parse()
    |> then(&Map.get(graph.nodes, &1))
    |> case do
      %{parent_guid: next_parent_guid} = node when is_binary(next_parent_guid) ->
        [node | ancestor_nodes(graph, next_parent_guid)]

      nil ->
        []

      node ->
        [node]
    end
  end

  defp focus_set(graph) do
    case Keyword.get(graph.options, :focus) do
      nil -> nil
      [] -> nil
      focus -> focus |> Enum.flat_map(&source_subtree(graph, &1)) |> MapSet.new()
    end
  end

  defp source_subtree(graph, guid) do
    children = Map.get(graph.children, guid, [])
    [guid | Enum.flat_map(children, &source_subtree(graph, &1))]
  end

  defp mark_stage(%Graph{} = graph, stage) do
    update_in(graph.stats[:resolved_stages], fn stages -> [stage | stages || []] end)
  end

  defp add_unresolved(%Graph{} = graph, item),
    do: %{graph | unresolved: [item | graph.unresolved]}

  defp materialized_seed_nodes(seed_nodes, options) do
    case Keyword.get(options, :focus) do
      nil -> seed_nodes
      [] -> seed_nodes
      focus -> focused_seed_nodes(seed_nodes, focus)
    end
  end

  defp focused_seed_nodes(seed_nodes, focus) do
    seed_by_guid = Map.new(seed_nodes, &{&1.guid, &1})
    children = build_children(seed_nodes)

    focused_guids =
      focus
      |> Enum.reduce(MapSet.new(), &collect_subtree(&2, &1, seed_by_guid, children))
      |> collect_instance_components(seed_by_guid, children)
      |> collect_ancestors(seed_by_guid)

    Enum.filter(seed_nodes, &MapSet.member?(focused_guids, &1.guid))
  end

  defp collect_instance_components(guids, seed_by_guid, children) do
    next =
      Enum.reduce(guids, guids, fn guid, acc ->
        case Map.get(seed_by_guid, guid) do
          %SeedNode{node_type: "instance"} = seed ->
            seed
            |> referenced_components()
            |> Enum.reduce(acc, &collect_subtree(&2, &1, seed_by_guid, children))

          _seed ->
            acc
        end
      end)

    if MapSet.size(next) == MapSet.size(guids) do
      next
    else
      collect_instance_components(next, seed_by_guid, children)
    end
  end

  defp referenced_components(seed) do
    symbol_ids = if is_tuple(seed.symbol_id), do: [seed.symbol_id], else: []

    swap_ids =
      seed.symbol_overrides
      |> Enum.flat_map(fn override ->
        assignment_ids =
          override.component_prop_assignments
          |> Enum.map(&component_assignment_guid/1)
          |> Enum.filter(&is_tuple/1)

        [override.overridden_symbol_id | assignment_ids]
      end)
      |> Enum.filter(&is_tuple/1)

    assignment_ids =
      seed.component_prop_assignments
      |> Enum.map(&component_assignment_guid/1)
      |> Enum.filter(&is_tuple/1)

    symbol_ids ++ swap_ids ++ assignment_ids
  end

  defp component_assignment_guid(%{value: {:guid, guid}}), do: guid
  defp component_assignment_guid(_assignment), do: nil

  defp collect_ancestors(guids, seed_by_guid) do
    Enum.reduce(guids, guids, &collect_ancestor(&2, &1, seed_by_guid))
  end

  defp collect_ancestor(guids, guid, seed_by_guid) do
    case Map.get(seed_by_guid, guid) do
      %{parent_guid: parent_guid} when is_tuple(parent_guid) ->
        guids
        |> MapSet.put(parent_guid)
        |> collect_ancestor(parent_guid, seed_by_guid)

      _seed ->
        guids
    end
  end

  defp collect_subtree(guids, guid, seed_by_guid, children) do
    if Map.has_key?(seed_by_guid, guid) do
      children
      |> Map.get(guid, [])
      |> Enum.reduce(MapSet.put(guids, guid), &collect_subtree(&2, &1, seed_by_guid, children))
    else
      guids
    end
  end

  defp build_children(seed_nodes) do
    seed_nodes
    |> Stream.with_index()
    |> Enum.reduce(%{}, fn
      {%SeedNode{parent_guid: nil}, _index}, acc ->
        acc

      {%SeedNode{parent_guid: parent_guid, guid: guid, position: position}, index}, acc ->
        entry = {guid, position || "", index}
        Map.update(acc, parent_guid, [entry], &[entry | &1])
    end)
    |> Map.new(fn {parent_guid, entries} ->
      children =
        entries
        |> Enum.sort_by(fn {_guid, position, index} -> {position, index} end)
        |> Enum.map(fn {guid, _position, _index} -> guid end)

      {parent_guid, children}
    end)
  end

  defp build_roots(seed_nodes) do
    guids = MapSet.new(seed_nodes, & &1.guid)

    seed_nodes
    |> Enum.filter(&(is_nil(&1.parent_guid) or not MapSet.member?(guids, &1.parent_guid)))
    |> Enum.map(& &1.guid)
  end

  defp component_prop_refs(seed_nodes) do
    Enum.reduce(seed_nodes, %{}, &add_component_prop_refs/2)
  end

  defp add_component_prop_refs(seed, refs) do
    Enum.reduce(seed.component_prop_refs, refs, &add_component_prop_ref(seed, &1, &2))
  end

  defp add_component_prop_ref(seed, prop_ref, refs) do
    with def_id when not is_nil(def_id) <- prop_ref.def_id,
         field when not is_nil(field) <- ComponentProps.field(prop_ref.field) do
      Map.update(refs, def_id, [{seed.guid, field}], &[{seed.guid, field} | &1])
    else
      _value -> refs
    end
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
