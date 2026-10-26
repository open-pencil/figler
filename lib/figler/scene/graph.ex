defmodule Figler.Scene.Graph do
  @moduledoc """
  Effective scene graph handle.

  `Figler.Scene.Index` is the fast raw projection of Kiwi node records.
  `Figler.Scene.Graph` is the surface for resolved Figma semantics: every
  instance is expanded into its own occurrences with swaps, component property
  assignments, symbol overrides, uniform scale, placed constraints, and saved
  derived data applied.

  Instances are resolved natively by an occurrence-scoped interpreter ported
  from OpenPencil's reader, and the graph stays in a native resource: nodes and
  records are read on demand with `fetch/2`, `record/3`, and `records/3`, or
  enumerated, and `to_map/2` materializes the parts a caller names. Layers
  inside an expansion have clone GUIDs (`"clone:<instance>/<source>/..."`) so
  each use of a component is addressable on its own. Overrides that cannot be
  resolved are reported by `unresolved/2` rather than failing the build.

  Malformed graph options and GUIDs raise `Figler.Error` with stable codes and
  structured context.
  """

  alias Figler.Error
  alias Figler.Native.Module, as: Native
  alias Figler.Scene
  alias Figler.Scene.Graph.Diff
  alias Figler.Scene.Graph.GUID
  alias Figler.Scene.Graph.Options
  alias Figler.Scene.Index
  alias Figler.Scene.Input
  alias Figler.Scene.Node
  alias Figler.Scene.Query
  alias Figler.Scene.Tree

  @enforce_keys [:resource]
  defstruct [
    :resource,
    :source,
    :native,
    mode: :interpreted,
    options: [],
    nodes: %{},
    children: %{},
    roots: [],
    by_type: %{},
    by_name: %{},
    stats: %{}
  ]

  @typedoc """
  Opaque effective scene graph resource.
  """
  @opaque t :: %__MODULE__{
            resource: reference() | nil,
            source: Index.t() | Scene.source() | reference() | nil,
            native: reference() | nil,
            mode: :interpreted | :projected,
            options: keyword(),
            nodes: %{optional(GUID.graph_guid()) => Node.t()},
            children: %{optional(GUID.graph_guid()) => [GUID.graph_guid()]},
            roots: [GUID.graph_guid()],
            by_type: %{optional(String.t()) => [GUID.graph_guid()]},
            by_name: %{optional(String.t()) => [GUID.graph_guid()]},
            stats: map()
          }

  @map_fields [:nodes, :records, :children, :roots, :by_type, :by_name, :provenance, :unresolved]

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

  defp interpret({payload, schema} = source, opts) do
    opts = normalize_options(opts)
    styles? = opts[:resolve_styles] == :known
    variables? = opts[:resolve_variables] == :known
    focus = opts |> Keyword.get(:focus, []) |> Enum.map(&GUID.format/1)

    {native, decode_us, index_us, interpret_us} =
      Native.graph_new(payload, schema, styles?, variables?, focus)

    graph = %__MODULE__{resource: nil, native: native, source: source, options: opts}

    phases = [
      %{phase: :decode, ms: ms(decode_us)},
      %{phase: :index, ms: ms(index_us)},
      %{phase: :interpret, ms: ms(interpret_us)}
    ]

    %{graph: graph, total_ms: Enum.reduce(phases, 0, &(&1.ms + &2)), phases: phases}
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
  Fetches the node at a GUID string.

      {:ok, node} = Figler.Scene.Graph.fetch(graph, "3740:112537")
  """
  @spec fetch(t(), String.t()) :: {:ok, Node.t()} | :error
  def fetch(%__MODULE__{} = graph, guid) when is_binary(guid) do
    case graph |> node_at(parse_guid!(:graph_fetch, guid)) |> Query.public_node() do
      nil -> :error
      node -> {:ok, node}
    end
  end

  @doc """
  Fetches the node at a GUID string, raising `KeyError` when the graph has none.
  """
  @spec fetch!(t(), String.t()) :: Node.t()
  def fetch!(%__MODULE__{} = graph, guid) when is_binary(guid) do
    case fetch(graph, guid) do
      {:ok, node} -> node
      :error -> raise KeyError, key: guid, term: graph
    end
  end

  @doc """
  Returns the effective record of a graph node: the sparse `NodeChange` map
  with every override resolved, or `nil`.

  Options:

    * `:fields` - the record fields to return, as atoms. Defaults to all.
    * `:as` - `:map` (default) for a sparse map, or `:struct` for the generated
      `Figler.Schema` structs.
  """
  @spec record(t(), String.t(), keyword()) :: map() | struct() | nil
  def record(%__MODULE__{} = graph, guid, opts \\ []) when is_binary(guid) and is_list(opts) do
    graph_guid = parse_guid!(:graph_record, guid)

    record =
      case graph do
        %__MODULE__{native: nil} -> nil
        %__MODULE__{native: native} -> Native.graph_record(native, graph_guid, field_names(opts))
      end

    record && shape_record(record, opts)
  end

  @doc """
  Returns the effective records of graph nodes by GUID string, leaving out GUIDs
  the graph lacks. Takes the options of `record/3`.
  """
  @spec records(t(), [String.t()], keyword()) :: %{optional(String.t()) => map() | struct()}
  def records(%__MODULE__{} = graph, guids, opts \\ []) when is_list(guids) and is_list(opts) do
    case graph do
      %__MODULE__{native: nil} ->
        %{}

      %__MODULE__{native: native} ->
        graph_guids = Enum.map(guids, &parse_guid!(:graph_records, &1))

        native
        |> Native.graph_records(graph_guids, field_names(opts))
        |> Map.new(fn {guid, record} -> {GUID.format(guid), shape_record(record, opts)} end)
    end
  end

  @doc """
  Materializes the parts of the graph named by `only:` as plain Elixir data,
  keyed by internal graph GUIDs:

    * `:nodes` - scene nodes by GUID
    * `:records` - effective records by GUID
    * `:children` - each parent's child GUIDs, in order
    * `:roots` - the source GUIDs the graph starts from
    * `:by_type` and `:by_name` - GUIDs by node type and by name
    * `:provenance` - where each node that is not a plain source node came from
    * `:unresolved` - the overrides the graph could not resolve

  Records and nodes of a whole document are large; name only what is needed.
  """
  @spec to_map(t(), keyword()) :: map()
  def to_map(%__MODULE__{} = graph, opts) when is_list(opts) do
    only = Keyword.fetch!(opts, :only)

    unless is_list(only) and only != [] and Enum.all?(only, &(&1 in @map_fields)) do
      raise ArgumentError, "only: expects a non-empty list of #{inspect(@map_fields)}"
    end

    case graph do
      %__MODULE__{native: nil} ->
        projected_fields = %{
          nodes: graph.nodes,
          records: %{},
          children: graph.children,
          roots: graph.roots,
          by_type: graph.by_type,
          by_name: graph.by_name,
          provenance: %{},
          unresolved: []
        }

        Map.take(projected_fields, only)

      %__MODULE__{native: native} ->
        native
        |> Native.graph_fields(Enum.map(only, &Atom.to_string/1))
        |> Map.take(only)
    end
  end

  @doc """
  Returns graph build/runtime stats.
  """
  @spec stats(t()) :: map()
  def stats(%__MODULE__{native: nil} = graph) do
    Map.merge(graph.stats, %{
      node_count: map_size(graph.nodes),
      clone_count: 0,
      instance_count: graph.by_type |> Map.get("instance", []) |> length(),
      unresolved_count: 0,
      applied_count: 0
    })
  end

  def stats(%__MODULE__{native: native} = graph),
    do: Map.merge(graph.stats, Native.graph_stats(native))

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

    case node_at(graph, graph_guid) do
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
          child_guids: graph |> child_guids(graph_guid) |> Enum.map(&GUID.format/1),
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

    case graph do
      %__MODULE__{native: nil} ->
        graph.nodes |> Map.get(source_guid) |> Query.public_node()

      %__MODULE__{native: native} ->
        native |> Native.graph_source_node(source_guid) |> Query.public_node()
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

    case node_at(graph, graph_guid) do
      %Node{node_type: "instance"} ->
        record = record(graph, guid) || %{}
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
    * `{:unsupported_variable_expression, variable, mode}`

  GUIDs are `{session_id, local_id}` tuples and `reason` is `:missing_target`
  or `:ambiguous_target`.
  """
  @spec unresolved(t(), keyword()) :: [term()]
  def unresolved(%__MODULE__{} = graph, opts \\ []) do
    Options.validate_unresolved!(opts)

    unresolved =
      case graph do
        %__MODULE__{native: nil} -> []
        %__MODULE__{native: native} -> Native.graph_unresolved(native)
      end

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
    resolved = graph |> node_at(graph_guid) |> Query.public_node()

    cond do
      is_nil(raw) and is_nil(resolved) -> nil
      raw == resolved -> %{guid: guid, changed: []}
      true -> %{guid: guid, raw: raw, resolved: resolved, changed: :unknown}
    end
  end

  @doc false
  @spec provenance(t(), GUID.graph_guid()) :: map()
  def provenance(%__MODULE__{} = graph, guid) do
    provenance =
      case graph do
        %__MODULE__{native: nil} -> nil
        %__MODULE__{native: native} -> Native.graph_provenance(native, guid)
      end

    provenance || %{source: :projected_index, source_guid: guid, applied: [], unresolved: []}
  end

  @doc false
  # The internal node at a graph GUID, whose GUIDs stay graph GUIDs.
  @spec node_at(t(), GUID.graph_guid()) :: Node.t() | nil
  def node_at(%__MODULE__{native: nil, nodes: nodes}, guid), do: Map.get(nodes, guid)
  def node_at(%__MODULE__{native: native}, guid), do: Native.graph_node(native, guid)

  @doc false
  # The effective record at a graph GUID, or `nil`.
  @spec record_at(t(), GUID.graph_guid()) :: map() | nil
  def record_at(%__MODULE__{native: nil}, _guid), do: nil
  def record_at(%__MODULE__{native: native}, guid), do: Native.graph_record(native, guid, nil)

  @doc false
  @spec nodes_at(t(), [GUID.graph_guid()]) :: [Node.t()]
  def nodes_at(%__MODULE__{native: nil, nodes: nodes}, guids),
    do: guids |> Enum.map(&Map.get(nodes, &1)) |> Enum.reject(&is_nil/1)

  def nodes_at(%__MODULE__{native: native}, guids), do: Native.graph_nodes(native, guids)

  @doc false
  # Every internal node, in graph order.
  @spec all_nodes(t()) :: [Node.t()]
  def all_nodes(%__MODULE__{native: nil, nodes: nodes}), do: Map.values(nodes)

  def all_nodes(%__MODULE__{native: native} = graph),
    do: Native.graph_node_slice(native, 0, node_count(graph))

  @doc false
  @spec all_guids(t()) :: [GUID.graph_guid()]
  def all_guids(%__MODULE__{native: nil, nodes: nodes}), do: Map.keys(nodes)
  def all_guids(%__MODULE__{native: native}), do: Native.graph_guids(native)

  @doc false
  @spec node_count(t()) :: non_neg_integer()
  def node_count(%__MODULE__{native: nil, nodes: nodes}), do: map_size(nodes)
  def node_count(%__MODULE__{native: native}), do: Native.graph_stats(native).node_count

  @doc false
  @spec child_guids(t(), GUID.graph_guid()) :: [GUID.graph_guid()]
  def child_guids(%__MODULE__{native: nil, children: children}, guid),
    do: Map.get(children, guid, [])

  def child_guids(%__MODULE__{native: native}, guid), do: Native.graph_children(native, guid)

  @doc false
  @spec root_guids(t()) :: [GUID.graph_guid()]
  def root_guids(%__MODULE__{native: nil, roots: roots}), do: roots
  def root_guids(%__MODULE__{native: native}), do: Native.graph_roots(native)

  @doc false
  @spec type_guids(t(), String.t()) :: [GUID.graph_guid()]
  def type_guids(%__MODULE__{native: nil, by_type: by_type}, type), do: Map.get(by_type, type, [])
  def type_guids(%__MODULE__{native: native}, type), do: Native.graph_of_type(native, type)

  @doc false
  @spec name_guids(t(), String.t()) :: [GUID.graph_guid()]
  def name_guids(%__MODULE__{native: nil, by_name: by_name}, name), do: Map.get(by_name, name, [])
  def name_guids(%__MODULE__{native: native}, name), do: Native.graph_named(native, name)

  @doc false
  # Internal nodes in graph order, `chunk` at a time, for enumeration.
  @spec node_chunks(t(), pos_integer()) :: Enumerable.t()
  def node_chunks(%__MODULE__{native: nil} = graph, _chunk), do: [all_nodes(graph)]

  def node_chunks(%__MODULE__{native: native} = graph, chunk) do
    count = node_count(graph)

    Stream.unfold(0, fn
      offset when offset >= count -> nil
      offset -> {Native.graph_node_slice(native, offset, chunk), offset + chunk}
    end)
  end

  defp component_node(_graph, nil), do: nil
  defp component_node(graph, guid), do: graph |> node_at(guid) |> Query.public_node()

  defp field_names(opts) do
    case Keyword.get(opts, :fields) do
      nil -> nil
      fields when is_list(fields) -> Enum.map(fields, &to_string/1)
    end
  end

  defp shape_record(record, opts) do
    case Keyword.get(opts, :as, :map) do
      :map -> record
      :struct -> to_struct(record)
    end
  end

  defp to_struct(%{__kiwi_module__: module} = record) do
    fields =
      record
      |> Map.delete(:__kiwi_module__)
      |> Map.new(fn {key, value} -> {key, to_struct(value)} end)

    struct(module, fields)
  end

  defp to_struct(values) when is_list(values), do: Enum.map(values, &to_struct/1)
  defp to_struct(value), do: value

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

  defimpl Enumerable do
    alias Figler.Scene.Graph
    alias Figler.Scene.Query

    # Public scene nodes, in graph order.
    def reduce(graph, acc, fun) do
      graph
      |> Graph.node_chunks(4096)
      |> Stream.flat_map(& &1)
      |> Stream.map(&Query.public_node/1)
      |> Enumerable.reduce(acc, fun)
    end

    def count(graph), do: {:ok, Graph.node_count(graph)}
    def member?(_graph, _node), do: {:error, __MODULE__}
    def slice(_graph), do: {:error, __MODULE__}
  end
end
