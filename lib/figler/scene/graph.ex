defmodule Figler.Scene.Graph do
  @moduledoc """
  Effective scene graph handle.

  `Figler.Scene.Index` is the fast raw projection of Kiwi node records.
  `Figler.Scene.Graph` is the surface for resolved Figma semantics: every
  instance is expanded into its own occurrences with swaps, component property
  assignments, symbol overrides, uniform scale, placed constraints, and saved
  derived data applied.

  Instances are resolved by `Figler.Scene.Graph.Occurrence.Interpreter`, a port
  of OpenPencil's occurrence-scoped reader. Layers inside an expansion have
  clone GUIDs (`"clone:<instance>/<source>/..."`) so each use of a component is
  addressable on its own. Overrides that cannot be resolved are reported by
  `unresolved/2` rather than failing the build.

  Malformed graph options and GUIDs raise `Figler.Error` with stable codes and
  structured context.
  """

  alias Figler.Error
  alias Figler.Native.CodecNifs
  alias Figler.Scene
  alias Figler.Scene.Graph.Diff
  alias Figler.Scene.Graph.GUID
  alias Figler.Scene.Graph.Materialize
  alias Figler.Scene.Graph.Occurrence.SourceIndex
  alias Figler.Scene.Graph.Options
  alias Figler.Scene.Graph.Variables
  alias Figler.Scene.Index
  alias Figler.Scene.Input
  alias Figler.Scene.Node
  alias Figler.Scene.Query
  alias Figler.Scene.Tree

  @enforce_keys [:resource]
  defstruct [
    :resource,
    :source,
    mode: :interpreted,
    options: [],
    sources: %{},
    records: %{},
    nodes: %{},
    children: %{},
    roots: [],
    by_type: %{},
    by_name: %{},
    provenance: %{},
    unresolved: [],
    stats: %{}
  ]

  @typedoc """
  Opaque effective scene graph resource.
  """
  @opaque t :: %__MODULE__{
            resource: reference() | nil,
            source: Index.t() | Scene.source() | reference() | nil,
            mode: :interpreted | :projected,
            options: keyword(),
            sources: %{optional(GUID.figma_guid()) => map()},
            records: %{optional(GUID.graph_guid()) => map()},
            nodes: %{optional(GUID.graph_guid()) => Node.t()},
            children: %{optional(GUID.graph_guid()) => [GUID.graph_guid()]},
            roots: [GUID.graph_guid()],
            by_type: %{optional(String.t()) => [GUID.graph_guid()]},
            by_name: %{optional(String.t()) => [GUID.graph_guid()]},
            provenance: %{optional(GUID.graph_guid()) => map()},
            unresolved: [term()],
            stats: map()
          }

  @doc """
  Builds an effective scene graph handle.

  Accepts the same binary inputs as `Figler.Scene.index/1`, a
  `t:Figler.Scene.source/0`, or another graph. A `%Figler.Scene.Index{}`
  or native index resource carries no override data, so it builds a projected
  graph with instances left unexpanded.

  Options:

    * `:focus` - one or more source GUIDs. Only their subtrees, ancestors, and
      the components they use are decoded and interpreted.
    * `:root` - alias for `:focus`, useful for resolving one subtree.
    * `:resolve_variables` - `:known` resolves each layer's variable bindings
      in the modes it uses; `false` or `:preserve` keeps the values the file
      saved. Defaults to `:known`.
    * `:resolve_styles` - `:known` applies the shared styles layers reference;
      `false` or `:refs` keeps the values the file saved. Defaults to `:known`.
    * `:fields` - fields to project when building from an index.
  """
  @spec build(binary() | Scene.source() | Index.t() | reference() | t(), keyword()) :: t()
  def build(input, opts \\ [])

  def build(%__MODULE__{} = graph, opts) when is_list(opts) do
    Options.validate_build!(opts)
    graph
  end

  def build({payload, schema} = source, opts)
      when is_binary(payload) and is_binary(schema) and is_list(opts) do
    Options.validate_build!(opts)
    Error.protect(:graph, fn -> source |> interpret(opts) |> Map.fetch!(:graph) end)
  end

  def build(binary, opts) when is_binary(binary) and is_list(opts) do
    Options.validate_build!(opts)

    Error.protect(:graph, fn ->
      binary |> Input.source!() |> interpret(opts) |> Map.fetch!(:graph)
    end)
  end

  def build(%Index{resource: resource} = index, opts) when is_list(opts) do
    Options.validate_build!(opts)
    Error.protect(:graph, fn -> projected(index, resource, opts) end)
  end

  def build(resource, opts) when is_reference(resource) and is_list(opts) do
    Options.validate_build!(opts)
    Error.protect(:graph, fn -> projected(resource, resource, opts) end)
  end

  @doc """
  Profiles graph construction.

  Returns the graph, the total time, and the time of each phase: `:decode`,
  `:index`, and `:interpret` (which includes materializing the graph).
  Options are the same as `build/2`.
  """
  @spec profile(binary() | Scene.source(), keyword()) :: map()
  def profile(input, opts \\ []) when is_list(opts) do
    Options.validate_build!(opts)

    Error.protect(:graph, fn ->
      source = if is_tuple(input), do: input, else: Input.source!(input)
      interpret(source, opts)
    end)
  end

  defp interpret(source, opts) do
    opts = normalize_options(opts)
    {decode_us, message} = :timer.tc(fn -> decode(source, opts) end)
    styles? = opts[:resolve_styles] == :known

    {index_us, index} =
      :timer.tc(fn -> SourceIndex.new(message.node_changes, styles: styles?) end)

    variables = if opts[:resolve_variables] == :known, do: Variables.new(index.sources)
    {interpret_us, fields} = :timer.tc(fn -> Materialize.graph(index, variables) end)

    attrs = [resource: nil, source: source, options: opts, sources: index.sources]
    graph = struct!(__MODULE__, Map.to_list(fields) ++ attrs)

    phases = [
      %{phase: :decode, ms: ms(decode_us)},
      %{phase: :index, ms: ms(index_us)},
      %{phase: :interpret, ms: ms(interpret_us)}
    ]

    %{graph: graph, total_ms: Enum.reduce(phases, 0, &(&1.ms + &2)), phases: phases}
  end

  defp decode(source, opts) do
    case Keyword.get(opts, :focus) do
      nil ->
        CodecNifs.decode_sparse_message(source)

      focus ->
        CodecNifs.decode_graph_focused_sparse_message(source, Enum.map(focus, &GUID.format/1))
    end
  end

  # A projected index has no override data: nodes keep their source records'
  # projection and instances stay unexpanded.
  defp projected(source, resource, opts) do
    nodes = Scene.query(source, "//*", fields: Keyword.get(opts, :fields, :all))
    by_guid = Map.new(nodes, &{GUID.parse!(&1.guid), %{&1 | children: nil}})
    guids = Map.keys(by_guid)

    %__MODULE__{
      resource: resource,
      source: source,
      mode: :projected,
      options: normalize_options(opts),
      nodes: by_guid,
      children:
        nodes
        |> Enum.filter(& &1.parent_guid)
        |> Enum.group_by(&GUID.parse!(&1.parent_guid), &GUID.parse!(&1.guid)),
      roots: for(node <- nodes, is_nil(node.parent_guid), do: GUID.parse!(node.guid)),
      by_type: Enum.group_by(guids, &by_guid[&1].node_type),
      by_name: guids |> Enum.reject(&is_nil(by_guid[&1].name)) |> Enum.group_by(&by_guid[&1].name)
    }
  end

  @doc """
  Returns graph build/runtime stats.
  """
  @spec stats(t()) :: map()
  def stats(%__MODULE__{} = graph) do
    Map.merge(graph.stats, %{
      node_count: map_size(graph.nodes),
      clone_count: clone_count(graph),
      instance_count: graph.by_type |> Map.get("instance", []) |> length(),
      unresolved_count: length(graph.unresolved),
      applied_count: applied_count(graph)
    })
  end

  @doc """
  Explains how a node appears in the effective graph.

  The explanation includes the resolved node, its projected source node,
  provenance, the property claims applied to it, and instance metadata for
  instance nodes.

      graph = Figler.Scene.graph(fig_binary, root: "3740:112537")
      Figler.Scene.Graph.explain(graph, "3740:112537")
  """
  @spec explain(t(), String.t()) :: map() | nil
  def explain(%__MODULE__{} = graph, guid) when is_binary(guid) do
    graph_guid = parse_guid!(:graph_explain, guid)

    case Map.get(graph.nodes, graph_guid) do
      nil ->
        nil

      %Node{} = node ->
        public_node = Query.public_node(node)
        provenance = provenance(graph, graph_guid)

        %{
          guid: GUID.format(graph_guid),
          node: public_node,
          source_node: source_node(graph, public_node.guid),
          source: provenance.source,
          source_guid: GUID.format(provenance.source_guid),
          parent_guid: public_node.parent_guid,
          child_guids: graph.children |> Map.get(graph_guid, []) |> Enum.map(&GUID.format/1),
          applied: Map.get(provenance, :applied, []),
          bindings: Map.get(provenance, :bindings, []),
          unresolved: Map.get(provenance, :unresolved, []),
          instance: instance(graph, public_node.guid)
        }
    end
  end

  @doc """
  Returns the projected source node a graph node was built from.
  """
  @spec source_node(t(), String.t()) :: Node.t() | nil
  def source_node(%__MODULE__{} = graph, guid) when is_binary(guid) do
    graph_guid = parse_guid!(:graph_source_node, guid)
    source_guid = provenance(graph, graph_guid).source_guid

    case Map.get(graph.sources, source_guid) do
      nil ->
        graph.nodes |> Map.get(source_guid) |> Query.public_node()

      record ->
        record
        |> Materialize.node(source_guid, SourceIndex.parent_id(record))
        |> Query.public_node()
    end
  end

  @doc """
  Returns the effective record of a graph node: the sparse `NodeChange` map
  with every override resolved.
  """
  @spec record(t(), String.t()) :: map() | nil
  def record(%__MODULE__{} = graph, guid) when is_binary(guid),
    do: Map.get(graph.records, parse_guid!(:graph_record, guid))

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
    Options.validate_tree!(opts)
    Tree.graph_tree(graph, opts)
  end

  @doc """
  Returns instance-specific effective graph metadata for a node.

  Returns `nil` for non-instance nodes.
  """
  @spec instance(t(), String.t()) :: map() | nil
  def instance(%__MODULE__{} = graph, guid) when is_binary(guid) do
    graph_guid = parse_guid!(:graph_instance, guid)

    case Map.get(graph.nodes, graph_guid) do
      %Node{node_type: "instance"} ->
        record = Map.get(graph.records, graph_guid, %{})
        provenance = provenance(graph, graph_guid)
        component_guid = Map.get(provenance, :component_guid)

        %{
          guid: GUID.format(graph_guid),
          component_guid: GUID.format(component_guid),
          component: component_node(graph, component_guid),
          component_prop_assignments: Map.get(record, :component_prop_assignments, []),
          symbol_overrides: get_in(record, [:symbol_data, :symbol_overrides]) || [],
          derived_symbol_data: Map.get(record, :derived_symbol_data, []),
          provenance: provenance
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
    Options.validate_diff!(opts)
    Diff.run(graph, opts)
  end

  @doc """
  Returns diagnostics for overrides the graph could not resolve.

    * `{:unresolved_property, owner, main_component, path, reason}`
    * `{:unresolved_assignment, owner, main_component, path, reason}`
    * `{:missing_component, owner, component}`
    * `{:missing_slot_content, slot, content}`

  GUIDs are `{session_id, local_id}` tuples and `reason` is `:missing_target`
  or `:ambiguous_target`.
  """
  @spec unresolved(t(), keyword()) :: [term()]
  def unresolved(%__MODULE__{unresolved: unresolved}, opts \\ []) do
    Options.validate_unresolved!(opts)

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
    graph_guid = parse_guid!(:graph_diff_node, guid)
    raw = Scene.node(index, guid)
    resolved = graph.nodes |> Map.get(graph_guid) |> Query.public_node()

    cond do
      is_nil(raw) and is_nil(resolved) -> nil
      raw == resolved -> %{guid: guid, changed: []}
      true -> %{guid: guid, raw: raw, resolved: resolved, changed: :unknown}
    end
  end

  @doc false
  @spec provenance(t(), GUID.graph_guid()) :: map()
  def provenance(%__MODULE__{} = graph, guid) do
    Map.get(graph.provenance, guid, %{
      source: :projected_index,
      source_guid: guid,
      applied: [],
      unresolved: []
    })
  end

  defp component_node(_graph, nil), do: nil
  defp component_node(graph, guid), do: graph.nodes |> Map.get(guid) |> Query.public_node()

  defp clone_count(graph) do
    Enum.count(graph.nodes, fn
      {{:clone, _root_guid, _source_path}, _node} -> true
      _entry -> false
    end)
  end

  defp applied_count(graph) do
    Enum.reduce(graph.provenance, 0, fn {_guid, provenance}, count ->
      count + length(Map.get(provenance, :applied, []))
    end)
  end

  defp normalize_options(opts) do
    opts
    |> normalize_focus()
    |> Keyword.delete(:root)
    |> Keyword.put_new(:resolve_variables, :known)
    |> Keyword.put_new(:resolve_styles, :known)
  end

  defp normalize_focus(opts) do
    case Keyword.get(opts, :focus, Keyword.get(opts, :root)) do
      nil -> opts
      focus -> Keyword.put(opts, :focus, parse_focus(focus))
    end
  end

  defp parse_focus(focus),
    do: focus |> List.wrap() |> Enum.map(&parse_guid!(:graph, &1)) |> Enum.uniq()

  defp ms(microseconds), do: microseconds / 1_000

  defp parse_guid!(operation, guid) do
    GUID.parse(guid) || raise Error.invalid_guid(operation, guid)
  end
end
