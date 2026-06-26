defmodule Figler.Scene.Graph do
  @moduledoc """
  Effective scene graph handle.

  `Figler.Scene.Index` is the fast raw projection of Kiwi node records.
  `Figler.Scene.Graph` is the separate surface intended for resolved Figma
  semantics: populated instances, symbol overrides, component props, derived
  symbol data, and variable/style resolution.

  The current graph keeps a pure Elixir working set seeded from the native raw
  index. Query and navigation APIs can already accept a graph, while resolver
  stages grow in Elixir where they are easier to inspect and verify.
  """

  alias Figler.Native.Codec
  alias Figler.Native.Scene, as: NativeScene
  alias Figler.Scene
  alias Figler.Scene.Graph.Diff
  alias Figler.Scene.Graph.GUID
  alias Figler.Scene.Graph.Resolver
  alias Figler.Scene.Graph.SeedNode
  alias Figler.Scene.Index
  alias Figler.Scene.Node
  alias Figler.Scene.Summary

  @enforce_keys [:resource]
  defstruct [
    :resource,
    :source,
    mode: :projected,
    stages: [],
    options: [],
    seed_nodes: %{},
    nodes: %{},
    children: %{},
    roots: [],
    by_type: %{},
    by_name: %{},
    clone_index: %{},
    clone_source_index: %{},
    component_prop_refs: %{},
    provenance: %{},
    unresolved: [],
    stats: %{}
  ]

  @typedoc """
  Opaque effective scene graph resource.
  """
  @opaque t :: %__MODULE__{
            resource: reference() | nil,
            source: Index.t() | binary() | nil,
            mode: :projected | :resolved,
            stages: [atom()],
            options: keyword(),
            seed_nodes: %{optional(GUID.graph_guid()) => SeedNode.t()},
            nodes: %{optional(GUID.graph_guid()) => Node.t()},
            children: %{optional(GUID.graph_guid()) => [GUID.graph_guid()]},
            roots: [GUID.graph_guid()],
            by_type: %{optional(String.t()) => [GUID.graph_guid()]},
            by_name: %{optional(String.t()) => [GUID.graph_guid()]},
            clone_index: %{optional({GUID.figma_guid(), GUID.graph_guid()}) => GUID.graph_guid()},
            clone_source_index: %{
              optional({GUID.figma_guid(), GUID.figma_guid()}) => GUID.graph_guid()
            },
            component_prop_refs: %{optional(GUID.figma_guid()) => {GUID.graph_guid(), atom()}},
            provenance: %{optional(GUID.graph_guid()) => map()},
            unresolved: [term()],
            stats: map()
          }

  @default_stages [
    :populate_instances,
    :symbol_overrides,
    :sync_overrides,
    :component_props,
    :sync_component_props,
    :derived_symbol_data,
    :stack_layout,
    :variables
  ]

  @doc """
  Builds an effective scene graph handle.

  Accepts the same binary inputs as `Figler.Scene.index/1`, an existing
  `%Figler.Scene.Index{}`, a native index resource, or another graph.

  Options are stored on the graph and define the intended resolver pipeline.
  The first implementation builds a pure Elixir working graph from structured
  seed nodes. Resolver stages are no-ops until their metadata extractors are
  wired, but the data shape and stage dispatcher are in place.

  Options:

    * `:stages` - explicit resolver stages. Defaults to the standard pipeline.
    * `:only` - alias for `:stages`, useful for focused debugging.
    * `:until` - include default stages through this stage.
    * `:skip` - remove stages from the selected pipeline.
    * `:focus` - one or more source GUIDs to resolve. When set, resolver stages
      only run from matching source instances and their source descendants.
    * `:root` - alias for `:focus`, useful for resolving one subtree.
    * `:resolve_variables` - `false`, `:known`, or `:preserve`. Defaults to `:known`.
    * `:resolve_styles` - `false`, `:refs`, or `:known`. Defaults to `false`.
    * `:fields` - optional projected fields hint for future graph materialization.
  """
  @spec build(binary() | Index.t() | reference() | t(), keyword()) :: t()
  def build(input, opts \\ [])

  def build(%__MODULE__{} = graph, opts) when is_list(opts) do
    if opts == [] do
      graph
    else
      %__MODULE__{graph | stages: stages(opts), options: normalize_options(opts)}
      |> Resolver.resolve()
    end
  end

  def build(%Index{resource: resource} = index, opts) when is_list(opts) do
    build_from_seed(index, resource, opts)
  end

  def build(binary, opts) when is_binary(binary) and is_list(opts) do
    payload = Scene.payload!(binary)
    seed_nodes = seed_nodes_from_payload(payload, opts)
    opts = maybe_pre_focused_opts(opts)

    if focused?(opts) do
      build_focused_from_seed(payload, opts, seed_nodes)
    else
      build_with_native_index(payload, opts, seed_nodes)
    end
  end

  def build(resource, opts) when is_reference(resource) and is_list(opts) do
    build_from_seed(nil, resource, opts)
  end

  @doc """
  Profiles graph construction and resolver stages.

  Returns the final graph, total build time, initial seed/materialization time,
  and per-stage timings. Options are the same as `build/2`.
  """
  @spec profile(binary() | Index.t() | reference() | t(), keyword()) :: map()
  def profile(input, opts \\ []) when is_list(opts) do
    selected_stages = stages(opts)
    base_opts = stage_profile_opts(opts, [])

    {initial_us, graph} = :timer.tc(fn -> build(input, base_opts) end)

    {stage_results, graph} =
      Enum.map_reduce(selected_stages, graph, fn stage, acc ->
        {stage_us, next} = :timer.tc(fn -> build(acc, stage_profile_opts(opts, stage)) end)

        {%{stage: stage, ms: native_ms(stage_us), graph: stats(next)}, next}
      end)

    initial_ms = native_ms(initial_us)

    %{
      graph: graph,
      initial_ms: initial_ms,
      total_ms: initial_ms + Enum.reduce(stage_results, 0, &(&1.ms + &2)),
      stages: stage_results
    }
  end

  @doc """
  Returns structured seed nodes for the graph resolver.
  """
  @spec seed_nodes(binary() | Index.t() | reference() | t(), keyword()) :: [SeedNode.t()]
  def seed_nodes(input, opts \\ [])

  def seed_nodes(%__MODULE__{seed_nodes: seed_nodes}, _opts) do
    Map.values(seed_nodes)
  end

  def seed_nodes(binary, opts) when is_binary(binary) do
    binary
    |> Scene.payload!()
    |> seed_nodes_from_payload(opts)
  end

  def seed_nodes(input, opts) when is_list(opts) do
    input
    |> Scene.query("//*", fields: Keyword.get(opts, :fields, :all))
    |> Enum.map(&SeedNode.from_node/1)
  end

  @doc """
  Returns graph build/runtime stats.
  """
  @spec stats(t()) :: map()
  def stats(%__MODULE__{} = graph) do
    Map.merge(graph.stats, %{
      node_count: map_size(graph.nodes),
      seed_count: map_size(graph.seed_nodes),
      clone_count: clone_count(graph),
      source_seed_count: seed_count(graph, :source),
      clone_seed_count: seed_count(graph, :clone),
      source_instance_count: instance_count(graph, :source),
      clone_instance_count: instance_count(graph, :clone),
      unresolved_count: length(graph.unresolved),
      applied_count: applied_count(graph)
    })
  end

  @doc """
  Explains how a node appears in the effective graph.

  The explanation includes the resolved node, projected source node when known,
  provenance, applied resolver operations, unresolved diagnostics recorded on
  the node, and instance metadata for instance nodes.

      graph = Figler.Scene.graph(fig_binary, root: "3740:112537")
      Figler.Scene.Graph.explain(graph, "3740:112537")
  """
  @spec explain(t(), String.t()) :: map() | nil
  def explain(%__MODULE__{} = graph, guid) when is_binary(guid) do
    graph_guid = GUID.parse!(guid)

    case Map.get(graph.nodes, graph_guid) do
      nil ->
        nil

      %Node{} = node ->
        %{
          guid: GUID.format(graph_guid),
          node: node,
          source_node: source_node(graph, node.guid),
          source: Map.get(provenance(graph, graph_guid), :source, :projected_index),
          source_guid:
            graph |> provenance(graph_guid) |> Map.get(:source_guid, graph_guid) |> GUID.format(),
          parent_guid: node.parent_guid,
          child_guids:
            graph
            |> Map.get(:children, %{})
            |> Map.get(graph_guid, [])
            |> Enum.map(&GUID.format/1),
          applied: Map.get(provenance(graph, graph_guid), :applied, []),
          unresolved: Map.get(provenance(graph, graph_guid), :unresolved, []),
          instance: instance(graph, node.guid),
          stages: graph.stages
        }
    end
  end

  @doc """
  Returns the projected source node for a graph node.
  """
  @spec source_node(t(), String.t()) :: Node.t() | nil
  def source_node(%__MODULE__{} = graph, guid) when is_binary(guid) do
    graph.seed_nodes
    |> Map.get(GUID.parse!(guid))
    |> case do
      nil -> nil
      seed -> SeedNode.to_node(seed)
    end
  end

  @doc """
  Returns a resolved tree from the effective graph.

  Options:

    * `:root` - graph GUID string/tuple to use as root. Defaults to all roots.
    * `:depth` - maximum child depth. Defaults to `3`.

      graph = Figler.Scene.graph(fig_binary, root: "3740:112537")
      Figler.Scene.Graph.tree(graph, root: "3740:112537", depth: 3)
  """
  @spec tree(t(), keyword()) :: [Node.t()] | Node.t() | nil
  def tree(%__MODULE__{} = graph, opts \\ []) when is_list(opts) do
    depth = Keyword.get(opts, :depth, 3)

    case Keyword.fetch(opts, :root) do
      {:ok, guid} ->
        graph_guid = GUID.parse!(guid)

        if node = Map.get(graph.nodes, graph_guid) do
          tree_node(graph, node, depth)
        end

      :error ->
        graph
        |> nodes_by_guids(graph.roots)
        |> Enum.map(&tree_node(graph, &1, depth))
    end
  end

  @doc """
  Returns instance-specific effective graph metadata for a node.

  Returns `nil` for non-instance nodes.
  """
  @spec instance(t(), String.t()) :: map() | nil
  def instance(%__MODULE__{} = graph, guid) when is_binary(guid) do
    graph_guid = GUID.parse!(guid)

    case Map.get(graph.nodes, graph_guid) do
      %Node{node_type: "instance"} = node ->
        seed = Map.get(graph.seed_nodes, graph_guid)
        component_guid = instance_component_guid(seed)

        %{
          guid: node.guid,
          component_guid: GUID.format(component_guid),
          component: component_node(graph, component_guid),
          component_prop_assignments: Map.get(seed || %{}, :component_prop_assignments, []),
          symbol_overrides: Map.get(seed || %{}, :symbol_overrides, []),
          derived_symbol_data: Map.get(seed || %{}, :derived_symbol_data, []),
          provenance: provenance(graph, graph_guid)
        }

      _node ->
        nil
    end
  end

  @doc """
  Diffs effective graph nodes against their projected source nodes.

  Returns only nodes whose projected source differs from the effective node.
  Pass `root:` to diff a subtree.
  """
  @spec diff(t(), keyword()) :: [map()]
  def diff(%__MODULE__{} = graph, opts \\ []) when is_list(opts) do
    Diff.run(graph, opts)
  end

  @doc """
  Returns unresolved graph items.
  """
  @spec unresolved(t(), keyword()) :: [term()]
  def unresolved(%__MODULE__{unresolved: unresolved}, opts \\ []) do
    case Keyword.get(opts, :limit, :all) do
      :all -> unresolved
      limit when is_integer(limit) and limit >= 0 -> Enum.take(unresolved, limit)
    end
  end

  @doc """
  Diffs one raw index node against its graph counterpart.
  """
  @spec diff_node(Index.t() | reference(), t(), String.t()) :: map() | nil
  def diff_node(index, %__MODULE__{} = graph, guid) when is_binary(guid) do
    raw = Scene.node(index, guid)
    resolved = Map.get(graph.nodes, GUID.parse!(guid))

    cond do
      is_nil(raw) and is_nil(resolved) -> nil
      raw == resolved -> %{guid: guid, changed: []}
      true -> %{guid: guid, raw: raw, resolved: resolved, changed: :unknown}
    end
  end

  defp build_focused_from_seed(payload, opts, seed_nodes) do
    nil
    |> build_from_seed(nil, opts, seed_nodes)
    |> Map.put(:source, payload)
  end

  defp build_with_native_index(payload, opts, seed_nodes) do
    {resource, summary_map} = NativeScene.build_index_with_summary(payload)
    index = %Index{resource: resource}
    summary = Summary.from_map(summary_map)
    %__MODULE__{} = graph = build_from_seed(index, resource, opts, seed_nodes)

    %__MODULE__{
      graph
      | stats:
          Map.merge(summary_stats(summary), Map.take(graph.stats, [:resolver, :resolved_stages]))
    }
  end

  defp seed_nodes_from_payload(payload, opts) do
    opts = normalize_focus(opts)

    if Keyword.get(opts, :native, true) do
      payload
      |> sparse_message(opts)
      |> SeedNode.from_message()
    else
      payload
      |> Figler.decode_message()
      |> SeedNode.from_message(opts)
    end
  end

  defp sparse_message(payload, opts) do
    case Keyword.get(opts, :focus) do
      nil -> Codec.decode_sparse_message(payload)
      [] -> Codec.decode_sparse_message(payload)
      focus -> Codec.decode_graph_focused_sparse_message(payload, Enum.map(focus, &GUID.format/1))
    end
  end

  defp focused?(opts), do: Keyword.has_key?(opts, :focus) or Keyword.has_key?(opts, :root)

  defp maybe_pre_focused_opts(opts) do
    if focused?(opts), do: Keyword.put(opts, :pre_focused, true), else: opts
  end

  defp stage_profile_opts(opts, stage) do
    opts
    |> Keyword.delete(:until)
    |> Keyword.delete(:stages)
    |> Keyword.put(:only, stage)
  end

  defp native_ms(microseconds),
    do: System.convert_time_unit(microseconds, :microsecond, :millisecond)

  defp build_from_seed(index, resource, opts, seed_nodes \\ nil) do
    stages = stages(opts)
    options = normalize_options(opts)
    seed_nodes = seed_nodes || seed_nodes(index || resource)

    seed_nodes
    |> Resolver.from_seed(resource: resource, source: index, stages: stages, options: options)
    |> Resolver.resolve()
  end

  defp clone_count(graph) do
    Enum.count(graph.nodes, fn
      {{:clone, _root_guid, _source_path}, _node} -> true
      _entry -> false
    end)
  end

  defp seed_count(graph, origin) do
    Enum.count(graph.seed_nodes, fn {_guid, seed} -> seed.origin == origin end)
  end

  defp instance_count(graph, origin) do
    Enum.count(graph.seed_nodes, fn {_guid, seed} ->
      seed.origin == origin and seed.node_type == "instance"
    end)
  end

  defp applied_count(graph) do
    Enum.reduce(graph.provenance, 0, fn {_guid, provenance}, count ->
      count + length(Map.get(provenance, :applied, []))
    end)
  end

  defp nodes_by_guids(%__MODULE__{} = graph, guids) do
    guids
    |> Enum.map(&Map.get(graph.nodes, &1))
    |> Enum.reject(&is_nil/1)
  end

  defp tree_node(_graph, %Node{} = node, 0), do: %Node{node | children: []}

  defp tree_node(graph, %Node{} = node, depth) do
    child_nodes = nodes_by_guids(graph, child_guids(graph, node.guid))
    %Node{node | children: Enum.map(child_nodes, &tree_node(graph, &1, depth - 1))}
  end

  defp child_guids(graph, guid), do: Map.get(graph.children, GUID.parse!(guid), [])

  defp instance_component_guid(%SeedNode{component_guid: guid}) when is_tuple(guid), do: guid
  defp instance_component_guid(%SeedNode{symbol_id: guid}) when is_tuple(guid), do: guid
  defp instance_component_guid(_seed), do: nil

  defp component_node(_graph, nil), do: nil
  defp component_node(graph, guid), do: Map.get(graph.nodes, guid)

  defp provenance(graph, guid), do: Map.get(graph.provenance, guid, %{})

  defp normalize_options(opts) do
    opts
    |> normalize_focus()
    |> Keyword.put_new(:resolve_variables, :known)
    |> Keyword.put_new(:resolve_styles, false)
  end

  defp normalize_focus(opts) do
    focus = Keyword.get(opts, :focus, Keyword.get(opts, :root))

    if is_nil(focus) do
      opts
    else
      Keyword.put(opts, :focus, parse_focus(focus))
    end
  end

  defp parse_focus(focus) do
    focus
    |> List.wrap()
    |> Enum.map(&GUID.parse!/1)
    |> Enum.uniq()
  end

  defp stages(opts) do
    selected =
      cond do
        Keyword.has_key?(opts, :only) -> List.wrap(Keyword.fetch!(opts, :only))
        Keyword.has_key?(opts, :stages) -> List.wrap(Keyword.fetch!(opts, :stages))
        until = Keyword.get(opts, :until) -> stages_until(until)
        true -> @default_stages
      end

    skip = opts |> Keyword.get(:skip, []) |> List.wrap()
    Enum.reject(selected, &(&1 in skip))
  end

  defp stages_until(until) do
    case Enum.find_index(@default_stages, &(&1 == until)) do
      nil -> @default_stages
      index -> Enum.take(@default_stages, index + 1)
    end
  end

  defp summary_stats(summary) do
    %{
      node_count: summary.node_count,
      parented_count: summary.parented_count,
      root_count: summary.root_count,
      type_counts: summary.type_counts
    }
  end
end
