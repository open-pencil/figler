defmodule Figler.Codegen.Native.Graph.Materialize do
  @moduledoc """
  Builds the effective graph from interpreted occurrence trees, natively.

  Every page is interpreted on its own. Layers inside an instance expansion get clone GUIDs that
  append each source GUID to the path from the outermost instance, so every occurrence has its
  own identity. Records outside the document tree become roots of their own. With variables,
  each layer's bindings resolve in the modes it and its ancestors set.
  """

  use RustQ.Meta,
    rust_sources: [
      "deps/kiwi_codec/codegen/kiwi_codec/rustler_generator/templates/records_runtime.rs"
    ],
    callable_modules: [
      Figler.Codegen.Native.Graph.Records,
      Figler.Codegen.Native.Graph.SourceIndex,
      Figler.Codegen.Native.Graph.Occurrence,
      Figler.Codegen.Native.Graph.Variables,
      Figler.Codegen.Native.Graph.VariableBindings,
      Figler.Codegen.Native.Graph.Interpreter
    ]

  alias Figler.Codegen.Native.Graph.Interpreter
  alias Figler.Codegen.Native.Graph.Occurrence
  alias Figler.Codegen.Native.Graph.SourceIndex
  alias Figler.Codegen.Native.Graph.Variables
  alias RustQ.Type, as: R

  defrustmod NodeChange, as: [:kiwi_records, :node_change]
  defrustmod NodeType, as: [:kiwi_records, :node_type]
  defrustmod VariableModeBySetMap, as: [:kiwi_records, :variable_mode_by_set_map]
  defrustmod VariableModeBySetMapEntry, as: [:kiwi_records, :variable_mode_by_set_map_entry]

  # A layer of an instance expansion: the outermost instance and the source GUIDs below it.
  @typep clone_guid ::
           R.hashable(%{required(:root) => GuidKey.t(), required(:path) => R.vec(GuidKey.t())})
  @typep graph_guid :: R.hashable(R.enum(source: [GuidKey.t()], clone: [clone_guid()]))

  # Where a layer came from: its source record, the instance whose expansion holds it, its
  # component, and the claims and bindings that changed it.
  @typep provenance :: %{
           required(:clone) => R.bool(),
           required(:source_guid) => GuidKey.t(),
           required(:instance_guid) => R.option(graph_guid()),
           required(:component_guid) => R.option(GuidKey.t()),
           required(:applied) => R.vec(Occurrence.property_claim()),
           required(:bindings) => R.vec(Occurrence.binding_claim())
         }

  @typep graph_node :: %{
           required(:guid) => graph_guid(),
           required(:parent) => R.option(graph_guid()),
           required(:record) => KiwiRecord.t(),
           required(:provenance) => R.option(provenance()),
           required(:children) => R.vec(R.usize())
         }

  @typep unresolved ::
           R.enum(
             variable: [Variables.unsupported_expression()],
             occurrence: [Interpreter.diagnostic()]
           )

  @typep graph :: %{
           required(:nodes) => R.vec(graph_node()),
           required(:positions) => HashMap.t(graph_guid(), R.usize()),
           required(:roots) => R.vec(GuidKey.t()),
           required(:unresolved) => R.vec(unresolved())
         }

  # Where an occurrence goes: its GUID, its parent's position, and the instance it is in.
  @typep placement :: %{
           required(:guid) => graph_guid(),
           required(:parent) => R.option(R.usize()),
           required(:owner) => R.option(graph_guid())
         }

  @doc false
  @spec items() :: [term()]
  def items do
    __rustq_type_items__() ++
      RustQ.Meta.AST.functions!(__MODULE__, [
        :build_graph,
        :root_ids,
        :put_root,
        :put_interpreted,
        :put_occurrence,
        :explicit_modes,
        :child_guid,
        :put_node,
        :provenance
      ])
  end

  # Interprets every root of `index` into a graph, resolving variables when given them.
  @spec build_graph(R.ref(SourceIndex.source_index()), R.option(R.ref(Variables.variables()))) ::
          R.nif_result(graph())
  defrust build_graph(index, vars) do
    unresolved =
      case vars do
        {:some, vars} ->
          for diagnostic <- vars.diagnostics.iter(), do: {:variable, diagnostic.clone()}

        :none ->
          Vec.new()
      end

    graph =
      struct_literal(Graph,
        nodes: Vec.new(),
        positions: HashMap.new(),
        roots: Vec.new(),
        unresolved: unresolved
      )

    for id <- root_ids(index) do
      put_root(index, mut_ref(graph), id, vars)
    end

    ok(graph)
  end

  # Records without a parent in the index, in GUID order.
  @spec root_ids(R.ref(SourceIndex.source_index())) :: R.vec(GuidKey.t())
  defrust root_ids(index) do
    roots =
      for {id, record} <- index.sources.iter(),
          parent_id(record).is_none_or(fn parent ->
            not index.sources.contains_key(ref(parent))
          end),
          do: deref(id)

    roots.sort()
    roots
  end

  # A document holds pages, which are interpreted one by one.
  @spec put_root(
          R.ref(SourceIndex.source_index()),
          R.mut_ref(graph()),
          GuidKey.t(),
          R.option(R.ref(Variables.variables()))
        ) :: R.nif_result(R.unit())
  defrust put_root(index, graph, id, vars) do
    graph.roots.push(id)

    case source(index, id) do
      {:some, record} when record.enum_value(NodeChange.TYPE) == some(NodeType.DOCUMENT) ->
        position = put_node(graph, {:source, id}, nil, record.clone(), nil)
        modes = explicit_modes(record, vars)

        for page <- children_of(index, id) do
          put_interpreted(index, graph, deref(page), some(position), ref(modes), vars)
        end

        ok(:ok)

      _ ->
        put_interpreted(index, graph, id, nil, ref(HashMap.new()), vars)
    end
  end

  @spec put_interpreted(
          R.ref(SourceIndex.source_index()),
          R.mut_ref(graph()),
          GuidKey.t(),
          R.option(R.usize()),
          R.ref(Variables.modes()),
          R.option(R.ref(Variables.variables()))
        ) :: R.nif_result(R.unit())
  defrust put_interpreted(index, graph, id, parent, modes, vars) do
    {occurrence, diagnostics} = interpret(index, id)

    graph.unresolved.extend(for diagnostic <- diagnostics, do: {:occurrence, diagnostic})

    placement = struct_literal(Placement, guid: {:source, id}, parent: parent, owner: nil)
    put_occurrence(graph, occurrence, placement, modes, vars)
    ok(:ok)
  end

  @spec put_occurrence(
          R.mut_ref(graph()),
          Occurrence.occurrence(),
          placement(),
          R.ref(Variables.modes()),
          R.option(R.ref(Variables.variables()))
        ) :: R.unit()
  defrust put_occurrence(graph, occurrence, placement, modes, vars) do
    modes = modes.clone()
    modes.extend(explicit_modes(ref(occurrence.properties), vars))

    record =
      case vars do
        {:some, vars} ->
          apply_bindings(occurrence.properties.clone(), ref(occurrence), ref(modes), vars)

        :none ->
          occurrence.properties.clone()
      end

    provenance = provenance(ref(occurrence), ref(placement.guid), ref(placement.owner))
    position = put_node(graph, placement.guid.clone(), placement.parent, record, provenance)

    owner =
      if instance?(ref(occurrence)),
        do: some(placement.guid.clone()),
        else: placement.owner.clone()

    instance = instance?(ref(occurrence))

    for child <- occurrence.children do
      guid = child_guid(ref(placement.guid), instance, child.source_id)

      child_placement =
        struct_literal(Placement, guid: guid, parent: some(position), owner: owner.clone())

      put_occurrence(graph, child, child_placement, ref(modes), vars)
    end
  end

  # The modes a layer sets explicitly, by collection.
  @spec explicit_modes(R.ref(KiwiRecord.t()), R.option(R.ref(Variables.variables()))) ::
          Variables.modes()
  defrust explicit_modes(record, vars) do
    modes = HashMap.new()

    case {vars, record.record(NodeChange.VARIABLE_MODE_BY_SET_MAP)} do
      {{:some, vars}, {:some, set_map}} ->
        for entry <- set_map.records(VariableModeBySetMap.ENTRIES) do
          collection =
            entry.record(VariableModeBySetMapEntry.VARIABLE_SET_ID)
            |> and_then(fn set -> reference(vars, set) end)

          mode = guid_key(entry.record(VariableModeBySetMapEntry.VARIABLE_MODE_ID))

          case {collection, mode} do
            {{:some, collection}, {:some, mode}} -> modes.insert(collection, mode)
            _ -> nil
          end
        end

      _ ->
        :ok
    end

    modes
  end

  # Layers of an instance expansion, and everything below them, are clones.
  @spec child_guid(R.ref(graph_guid()), R.bool(), GuidKey.t()) :: graph_guid()
  defrust child_guid(guid, instance, child) do
    case guid do
      {:clone, clone} ->
        path = clone.path.clone()
        path.push(child)
        {:clone, struct_literal(CloneGuid, root: clone.root, path: path)}

      {:source, id} when instance ->
        {:clone, struct_literal(CloneGuid, root: deref(id), path: [child])}

      _ ->
        {:source, child}
    end
  end

  @spec put_node(
          R.mut_ref(graph()),
          graph_guid(),
          R.option(R.usize()),
          KiwiRecord.t(),
          R.option(provenance())
        ) :: R.usize()
  defrust put_node(graph, guid, parent, record, provenance) do
    position = graph.nodes.len()
    parent_guid = parent.map(fn parent -> graph.nodes[parent].guid.clone() end)

    case parent do
      {:some, parent} -> graph.nodes[parent].children.push(position)
      :none -> :ok
    end

    graph.positions.insert(guid.clone(), position)

    graph.nodes.push(
      struct_literal(GraphNode,
        guid: guid,
        parent: parent_guid,
        record: record,
        provenance: provenance,
        children: Vec.new()
      )
    )

    position
  end

  # Source nodes keep the default projected provenance unless they are instances or carry
  # claims; every clone records where it came from.
  @spec provenance(
          R.ref(Occurrence.occurrence()),
          R.ref(graph_guid()),
          R.ref(R.option(graph_guid()))
        ) ::
          R.option(provenance())
  defrust provenance(occurrence, guid, owner) do
    clone =
      case guid do
        {:clone, _clone} -> true
        {:source, _id} -> false
      end

    if clone or instance?(occurrence) or not occurrence.property_claims.is_empty() or
         not occurrence.binding_claims.is_empty() do
      some(
        struct_literal(Provenance,
          clone: clone,
          source_guid: occurrence.source_id,
          instance_guid: owner.clone(),
          component_guid: occurrence.main_component_id,
          applied: occurrence.property_claims.clone(),
          bindings: occurrence.binding_claims.clone()
        )
      )
    else
      nil
    end
  end
end
