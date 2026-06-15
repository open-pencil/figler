defmodule FigKiwi.Scene.Graph do
  @moduledoc """
  Effective scene graph handle.

  `FigKiwi.Scene.Index` is the fast raw projection of Kiwi node records.
  `FigKiwi.Scene.Graph` is the separate surface intended for resolved Figma
  semantics: populated instances, symbol overrides, component props, derived
  symbol data, and variable/style resolution.

  The current graph keeps a pure Elixir working set seeded from the native raw
  index. Query and navigation APIs can already accept a graph, while resolver
  stages grow in Elixir where they are easier to inspect and verify.
  """

  alias FigKiwi.Native.Codec
  alias FigKiwi.Scene
  alias FigKiwi.Scene.Graph.GUID
  alias FigKiwi.Scene.Graph.Resolver
  alias FigKiwi.Scene.Graph.SeedNode
  alias FigKiwi.Scene.Index
  alias FigKiwi.Scene.Node

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
    component_prop_refs: %{},
    provenance: %{},
    unresolved: [],
    stats: %{}
  ]

  @typedoc """
  Opaque effective scene graph resource.
  """
  @opaque t :: %__MODULE__{
            resource: reference(),
            source: Index.t() | nil,
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
    :variables
  ]

  @doc """
  Builds an effective scene graph handle.

  Accepts the same binary inputs as `FigKiwi.Scene.index/1`, an existing
  `%FigKiwi.Scene.Index{}`, a native index resource, or another graph.

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
    index = Scene.index(binary)
    summary = Scene.summary(binary)
    seed_nodes = seed_nodes(binary)
    %__MODULE__{} = graph = build_from_seed(index, index.resource, opts, seed_nodes)

    %__MODULE__{
      graph
      | stats:
          Map.merge(summary_stats(summary), Map.take(graph.stats, [:resolver, :resolved_stages]))
    }
  end

  def build(resource, opts) when is_reference(resource) and is_list(opts) do
    build_from_seed(nil, resource, opts)
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
    payload = Scene.payload!(binary)

    if Keyword.get(opts, :native, true) do
      payload
      |> Codec.decode_sparse_message()
      |> SeedNode.from_message()
    else
      payload
      |> FigKiwi.decode_message()
      |> SeedNode.from_message()
    end
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
  Explains how a node appears in the graph.

  This is deliberately shaped for the future resolver. Today it reports the raw
  projected node and no applied resolver operations.
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
          source: Map.get(provenance(graph, graph_guid), :source, :projected_index),
          source_guid:
            graph |> provenance(graph_guid) |> Map.get(:source_guid, graph_guid) |> GUID.format(),
          applied: Map.get(provenance(graph, graph_guid), :applied, []),
          unresolved: Map.get(provenance(graph, graph_guid), :unresolved, []),
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
  Diffs a raw index and graph node-by-node.

  This placeholder returns an empty diff while the graph is backed directly by
  the projected index.
  """
  @spec diff(Index.t() | reference(), t()) :: []
  def diff(_index, %__MODULE__{}), do: []

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
