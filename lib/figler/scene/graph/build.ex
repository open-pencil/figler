defmodule Figler.Scene.Graph.Build do
  @moduledoc """
  Pure Elixir build and resolver pipeline for `Figler.Scene.Graph`.

  The resolver intentionally starts from structured seed nodes and ordinary
  Elixir maps so Figma semantics can be inspected, tested, and changed quickly.
  Rust remains the fast decoder/projector; this module owns the evolving
  override rules.
  """

  alias Figler.Scene.Graph
  alias Figler.Scene.Graph.Build.ClonePopulation
  alias Figler.Scene.Graph.Build.DerivedData
  alias Figler.Scene.Graph.Build.Focus
  alias Figler.Scene.Graph.Build.SourceInstances
  alias Figler.Scene.Graph.Build.StackLayout
  alias Figler.Scene.Graph.Build.Variables
  alias Figler.Scene.Graph.Component.Properties, as: ComponentProps
  alias Figler.Scene.Graph.Nodes
  alias Figler.Scene.Graph.Provenance
  alias Figler.Scene.Graph.Seed.Node, as: SeedNode
  alias Figler.Scene.Graph.Symbol.OverrideApplication

  @doc """
  Builds the initial graph working set from seed nodes.
  """
  @spec from_seed([SeedNode.t()], keyword()) :: Graph.t()
  def from_seed(seed_nodes, opts \\ []) when is_list(seed_nodes) and is_list(opts) do
    options = Keyword.get(opts, :options, [])

    seed_nodes
    |> Focus.materialize(options)
    |> initial_indexes()
    |> from_initial_indexes(opts, options)
  end

  @doc false
  @spec from_native_records([tuple()], keyword()) :: Graph.t()
  def from_native_records(records, opts \\ []) when is_list(records) and is_list(opts) do
    options = Keyword.get(opts, :options, [])

    records
    |> initial_native_indexes()
    |> from_initial_indexes(opts, options)
  end

  defp from_initial_indexes(initial, opts, options) do
    children = build_children(initial.children_entries)
    roots = build_roots(initial.root_entries, initial.seed_nodes)

    %Graph{
      resource: Keyword.fetch!(opts, :resource),
      source: Keyword.get(opts, :source),
      mode: :projected,
      stages: Keyword.get(opts, :stages, []),
      projection_stages: Keyword.get(opts, :projection_stages, :all),
      options: options,
      seed_nodes: initial.seed_nodes,
      nodes: initial.nodes,
      children: children,
      roots: roots,
      by_type: reverse_group_values(initial.by_type),
      by_name: reverse_group_values(initial.by_name),
      clone_index: %{},
      clone_source_index: %{},
      source_instance_guids: source_instance_guids(initial.seed_nodes),
      stack_seed_guids: Enum.reverse(initial.stack_seed_guids),
      component_prop_refs: initial.component_prop_refs,
      provenance: Provenance.initial(),
      unresolved: [],
      stats: stats(initial.seed_nodes, children, roots)
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

  @doc false
  @spec resolve_stage(Graph.t(), atom(), [atom()]) :: Graph.t()
  def resolve_stage(%Graph{} = graph, stage, remaining_stages) do
    run_stage(stage, %Graph{graph | stages: remaining_stages})
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
    |> SourceInstances.list()
    |> Enum.reduce(graph, &ClonePopulation.apply(&2, &1))
    |> mark_stage(:populate_instances)
  end

  defp apply_symbol_overrides(graph) do
    graph
    |> OverrideApplication.apply(SourceInstances.list(graph))
    |> reindex_unless_later(:symbol_overrides, :component_props)
    |> mark_stage(:symbol_overrides)
  end

  defp sync_overrides(graph), do: mark_stage(graph, :sync_overrides)

  defp apply_component_props(graph) do
    graph
    |> ComponentProps.apply_all()
    |> Nodes.reindex()
    |> mark_stage(:component_props)
  end

  defp sync_component_props(graph), do: mark_stage(graph, :sync_component_props)

  defp apply_derived_symbol_data(graph) do
    graph
    |> SourceInstances.list()
    |> Enum.reduce(graph, &DerivedData.apply(&2, &1))
    |> mark_stage(:derived_symbol_data)
  end

  defp apply_stack_layout(graph) do
    graph
    |> StackLayout.apply()
    |> mark_stage(:stack_layout)
  end

  defp resolve_variables(graph) do
    graph
    |> Variables.apply()
    |> mark_stage(:variables)
  end

  defp mark_stage(%Graph{} = graph, stage) do
    update_in(graph.stats[:resolved_stages], fn stages -> [stage | stages || []] end)
  end

  defp reindex_unless_later(%Graph{} = graph, current_stage, later_stage) do
    if later_stage?(graph.stages, current_stage, later_stage) do
      graph
    else
      Nodes.reindex(graph)
    end
  end

  defp later_stage?(stages, current_stage, later_stage) do
    stages
    |> Enum.drop_while(&(&1 != current_stage))
    |> case do
      [] -> false
      [_current | later_stages] -> later_stage in later_stages
    end
  end

  defp add_unresolved(%Graph{} = graph, item),
    do: %{graph | unresolved: [item | graph.unresolved]}

  defp initial_indexes(seed_nodes) do
    Enum.reduce(seed_nodes, initial_indexes(), &add_initial_seed/2)
  end

  defp initial_native_indexes(records) do
    Enum.reduce(records, initial_indexes(), fn record, acc ->
      record |> SeedNode.from_native_record() |> add_initial_seed(acc)
    end)
  end

  defp initial_indexes do
    %{
      index: 0,
      nodes: %{},
      seed_nodes: %{},
      children_entries: %{},
      root_entries: [],
      by_type: %{},
      by_name: %{},
      stack_seed_guids: [],
      component_prop_refs: %{}
    }
  end

  defp add_initial_seed(%SeedNode{} = seed, acc) do
    %{
      acc
      | index: acc.index + 1,
        nodes: Map.put(acc.nodes, seed.guid, SeedNode.to_graph_node(seed)),
        seed_nodes: Map.put(acc.seed_nodes, seed.guid, seed),
        children_entries: add_child_entry(acc.children_entries, seed, acc.index),
        root_entries: [{seed.guid, seed.parent_guid} | acc.root_entries],
        by_type: add_group_guid(acc.by_type, seed.node_type, seed.guid),
        by_name: add_group_guid(acc.by_name, seed.name, seed.guid),
        stack_seed_guids:
          add_candidate_guid(acc.stack_seed_guids, seed, &SeedNode.stack_candidate?/1),
        component_prop_refs: ComponentProps.add_seed_refs(seed, acc.component_prop_refs)
    }
  end

  defp add_child_entry(children, %SeedNode{parent_guid: nil}, _index), do: children

  defp add_child_entry(
         children,
         %SeedNode{parent_guid: parent_guid, guid: guid, position: position},
         index
       ) do
    entry = {guid, position || "", index}
    Map.update(children, parent_guid, [entry], &[entry | &1])
  end

  defp build_children(children_entries) do
    Map.new(children_entries, fn {parent_guid, entries} ->
      children =
        entries
        |> Enum.sort_by(fn {_guid, position, index} -> {position, index} end)
        |> Enum.map(fn {guid, _position, _index} -> guid end)

      {parent_guid, children}
    end)
  end

  defp build_roots(root_entries, seed_nodes_by_guid) do
    root_entries
    |> Enum.reverse()
    |> Enum.filter(fn {_guid, parent_guid} ->
      is_nil(parent_guid) or not Map.has_key?(seed_nodes_by_guid, parent_guid)
    end)
    |> Enum.map(&elem(&1, 0))
  end

  defp add_candidate_guid(guids, seed, predicate) do
    if predicate.(seed), do: [seed.guid | guids], else: guids
  end

  defp add_group_guid(groups, nil, _guid), do: groups
  defp add_group_guid(groups, "", _guid), do: groups
  defp add_group_guid(groups, key, guid), do: Map.update(groups, key, [guid], &[guid | &1])

  defp source_instance_guids(seed_nodes) do
    Enum.flat_map(seed_nodes, fn
      {guid, %SeedNode{origin: :source, node_type: "instance"}} -> [guid]
      _entry -> []
    end)
  end

  defp reverse_group_values(groups) do
    Map.new(groups, fn {key, values} -> {key, Enum.reverse(values)} end)
  end

  defp stats(seed_nodes, children, roots) do
    %{
      resolver: :elixir,
      node_count: map_size(seed_nodes),
      parented_count:
        Enum.reduce(children, 0, fn {_parent, guids}, count -> count + length(guids) end),
      root_count: length(roots),
      resolved_stages: []
    }
  end
end
