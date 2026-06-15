defmodule FigKiwi.Scene.Graph.Resolver do
  @moduledoc """
  Pure Elixir resolver pipeline for `FigKiwi.Scene.Graph`.

  The resolver intentionally starts from structured seed nodes and ordinary
  Elixir maps so Figma semantics can be inspected, tested, and changed quickly.
  Rust remains the fast decoder/projector; this module owns the evolving
  override rules.
  """

  alias FigKiwi.Scene.Graph
  alias FigKiwi.Scene.Graph.SeedNode

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

  defp populate_instances(graph), do: mark_stage(graph, :populate_instances)
  defp apply_symbol_overrides(graph), do: mark_stage(graph, :symbol_overrides)
  defp sync_overrides(graph), do: mark_stage(graph, :sync_overrides)
  defp apply_component_props(graph), do: mark_stage(graph, :component_props)
  defp sync_component_props(graph), do: mark_stage(graph, :sync_component_props)
  defp apply_derived_symbol_data(graph), do: mark_stage(graph, :derived_symbol_data)
  defp resolve_variables(graph), do: mark_stage(graph, :variables)

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
