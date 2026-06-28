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
    seed_nodes = Focus.materialize(seed_nodes, options)
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
      clone_source_index: %{},
      component_prop_refs: ComponentProps.index(seed_nodes),
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
    |> SourceInstances.list()
    |> Enum.reduce(graph, &ClonePopulation.apply(&2, &1))
    |> mark_stage(:populate_instances)
  end

  defp apply_symbol_overrides(graph) do
    graph
    |> OverrideApplication.apply(SourceInstances.list(graph))
    |> Nodes.reindex()
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

  defp add_unresolved(%Graph{} = graph, item),
    do: %{graph | unresolved: [item | graph.unresolved]}

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
