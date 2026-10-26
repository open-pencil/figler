defmodule Figler.Codegen.Native.Graph.Interpreter do
  @moduledoc """
  Expands source records into occurrence trees, resolving instances, natively.

  A port of OpenPencil's occurrence-scoped instance interpreter. An instance expands its
  component's subtree; owners contribute layers, each a partial record at a path relative to
  that owner; where layers overlap, the outermost owner wins.

  Swaps and property assignments are structural layers, routed down to the instance they
  configure before it expands. Every other override is a property claim, applied by its owner
  onto the built subtree, inner owners before outer ones. Saved derived data is a cache, applied
  last. Unresolvable overrides become diagnostics; overrides addressing a component an outer
  swap replaced are stale and dropped.
  """

  use RustQ.Meta,
    callable_modules: [
      Figler.Codegen.Native.Graph.Records,
      Figler.Codegen.Native.Graph.SourceIndex,
      Figler.Codegen.Native.Graph.Occurrence,
      Figler.Codegen.Native.Graph.Claims,
      Figler.Codegen.Native.Graph.Bindings,
      Figler.Codegen.Native.Graph.Layer,
      Figler.Codegen.Native.Graph.Geometry
    ]

  alias Figler.Codegen.Native.Graph.Bindings
  alias Figler.Codegen.Native.Graph.Layer
  alias Figler.Codegen.Native.Graph.Occurrence
  alias Figler.Codegen.Native.Graph.SourceIndex
  alias Figler.Codegen.Native.Graph.Records
  alias KiwiCodec.RustlerGenerator.Records, as: Kiwi
  alias RustQ.Type, as: R

  @typep diagnostic_kind ::
           :unresolved_property
           | :unresolved_assignment
           | :missing_component
           | :missing_slot_content

  @typep target_reason :: :missing_target | :ambiguous_target

  # `component` is the main component of an unresolved override's owner, the component a
  # missing-component owner names, or the content a slot names.
  @typep diagnostic :: %{
           required(:kind) => diagnostic_kind(),
           required(:owner) => Records.guid_key(),
           required(:component) => R.option(Records.guid_key()),
           required(:path) => R.vec(Records.guid_key()),
           required(:reason) => R.option(target_reason())
         }

  @typep pending :: %{
           required(:path) => R.vec(Records.guid_key()),
           required(:reason) => target_reason()
         }

  @typep state :: %{
           required(:expanding) => HashSet.t(Records.guid_key()),
           required(:diagnostics) => R.vec(diagnostic()),
           required(:pending) => HashMap.t(Records.guid_key(), R.vec(pending()))
         }

  # A record bound from its enclosing component scope.
  @typep bound_record :: %{
           required(:source) => Kiwi.kiwi_record(),
           required(:claims) => R.vec(Occurrence.binding_claim()),
           required(:bound) => HashMap.t(R.u32(), R.u32()),
           required(:superseded) => R.vec(Records.guid_key()),
           required(:slot_content) => R.option(Records.guid_key())
         }

  @typep group :: %{
           required(:assignments) => R.vec(Kiwi.kiwi_record()),
           required(:rank) => R.u32()
         }

  # The component an occurrence expands and the layers left for its descendants.
  @typep root :: %{
           required(:effective) => R.option(Records.guid_key()),
           required(:replaced) => R.vec(Records.guid_key()),
           required(:keys) => R.vec(Records.guid_key()),
           required(:groups) => R.vec(group()),
           required(:descendant) => R.vec(Layer.layer())
         }

  # The component expansion an occurrence's children come from. `dangling` marks an instance
  # whose component is gone: only the record itself remains addressable.
  @typep subtree :: %{
           required(:base) => R.option(Occurrence.occurrence()),
           required(:dangling) => R.bool()
         }

  @doc "The Rust types and functions this module defines."
  @spec items() :: [term()]
  def items, do: __rustq_items__()

  # Interprets a page, component, or instance record: the occurrence tree and the diagnostics
  # collected while expanding it. Slot content frames are left out of a page's children: they
  # are read through the instance that assigns them.
  @spec interpret(R.ref(SourceIndex.source_index()), Records.guid_key()) ::
          R.nif_result({Occurrence.occurrence(), R.vec(diagnostic())})
  defrust interpret(index, root_id) do
    state =
      struct_literal(State, expanding: MapSet.new(), diagnostics: [], pending: %{})

    occurrence = expand(index, root_id, [], [], 0, mut_ref(state))
    ok({drop_slot_content(index, occurrence), state.diagnostics})
  end

  @spec drop_slot_content(R.ref(SourceIndex.source_index()), Occurrence.occurrence()) ::
          Occurrence.occurrence()
  defrust drop_slot_content(index, occurrence) do
    if node_type(index, occurrence.source_id) == some(Kiwi.NodeType.CANVAS) do
      children =
        for child <- occurrence.children,
            not child.properties.bool(Kiwi.NodeChange.IS_SLOT_CONTENT).unwrap_or(false),
            do: child

      %{occurrence | children: children}
    else
      occurrence
    end
  end

  # Expands one source record. `layers` are structural layers addressed relative to this
  # expansion: an empty path configures the record itself.
  @spec expand(
          R.ref(SourceIndex.source_index()),
          Records.guid_key(),
          R.slice(Bindings.binding()),
          R.vec(Layer.layer()),
          R.u32(),
          R.mut_ref(state())
        ) :: R.nif_result(Occurrence.occurrence())
  defrust expand(index, id, bindings, layers, rank, state) do
    case source(index, id) do
      {:some, raw} when not MapSet.member?(state.expanding, id) ->
        expand_source(index, id, raw, bindings, layers, rank, state)

      _ ->
        err(badarg())
    end
  end

  @spec expand_source(
          R.ref(SourceIndex.source_index()),
          Records.guid_key(),
          R.ref(Kiwi.kiwi_record()),
          R.slice(Bindings.binding()),
          R.vec(Layer.layer()),
          R.u32(),
          R.mut_ref(state())
        ) :: R.nif_result(Occurrence.occurrence())
  defrust expand_source(index, id, raw, bindings, layers, rank, state) do
    record = bind_record(index, raw, bindings, state)
    state.expanding.insert(id)

    owner = struct_literal(LayerOwner, id: id, rank: rank)
    {structural, own_claims} = own(record.source, owner.clone())
    structural = Enum.sort_by(structural ++ layers, fn layer -> layer.owner.rank end, :desc)
    root = resolve_root(index, raw, record, structural, rank)

    {subtree, children} =
      expand_subtree(index, owner, record, bindings, root, rank, state)

    base = subtree.base.as_ref()

    occurrence =
      create_occurrence(index, id, raw, record.source, root, base, children)

    occurrence = %{
      occurrence
      | binding_claims: record.claims.clone(),
        slot_content_id: record.slot_content,
        bound_fields: record.bound.clone(),
        overridden: assigned_visibility(record.claims),
        replaced_components: if(base != nil, do: root.replaced.clone(), else: [])
    }

    claims =
      if subtree.dangling,
        do: for(claim <- own_claims, root_claim?(occurrence, claim), do: claim),
        else: own_claims

    occurrence =
      finish_occurrence(index, occurrence, subtree, record.source, claims, rank, state)

    report_owner(state, id, occurrence.main_component_id)
    state.expanding.remove(ref(id))
    ok(occurrence)
  end

  @spec expand_subtree(
          R.ref(SourceIndex.source_index()),
          R.ref(Layer.layer_owner()),
          R.ref(bound_record()),
          R.slice(Bindings.binding()),
          R.ref(root()),
          R.u32(),
          R.mut_ref(state())
        ) :: R.nif_result({subtree(), R.vec(Occurrence.occurrence())})
  defrust expand_subtree(index, owner, record, bindings, root, rank, state) do
    case {root.effective, record.slot_content} do
      {{:some, _effective}, _content} ->
        expand_base(index, owner, root, rank, state)

      {:none, {:some, content}} ->
        expand_children_of(index, content, [], root.descendant, rank, state)

      _ when record.source.enum_value(Kiwi.NodeChange.TYPE) == some(Kiwi.NodeType.SYMBOL) ->
        expand_children_of(
          index,
          owner.id,
          scoped_bindings(record.source, root.groups),
          root.descendant,
          rank,
          state
        )

      _ ->
        expand_children_of(index, owner.id, bindings, root.descendant, rank, state)
    end
  end

  @spec root_claim?(R.ref(Occurrence.occurrence()), R.ref(Layer.claim())) :: R.bool()
  defrust root_claim?(occurrence, claim) do
    case claim.path do
      [segment] -> root_guid?(occurrence, segment)
      _ -> false
    end
  end

  # Binds the record's fields from the enclosing component scope.
  @spec bind_record(
          R.ref(SourceIndex.source_index()),
          R.ref(Kiwi.kiwi_record()),
          R.slice(Bindings.binding()),
          R.mut_ref(state())
        ) :: bound_record()
  defrust bind_record(index, raw, bindings, state) do
    {source, bound_claims} = bind(raw, bindings)

    unbound =
      struct_literal(BoundRecord,
        source: source,
        claims: [],
        bound: %{},
        superseded: [],
        slot_content: nil
      )

    record =
      Enum.reduce(bound_claims, unbound, fn {claim, binding}, record ->
        collect_binding(record, claim, binding)
      end)

    case record.slot_content do
      {:some, content} when not Map.has_key?(index.sources, content) ->
        state.diagnostics.push(
          struct_literal(Diagnostic,
            kind: :missing_slot_content,
            owner: record_id(raw).unwrap_or_default(),
            component: some(content),
            path: [],
            reason: nil
          )
        )

        %{record | slot_content: nil}

      _ ->
        record
    end
  end

  @spec collect_binding(
          bound_record(),
          R.ref(Occurrence.binding_claim()),
          R.ref(Bindings.binding())
        ) ::
          bound_record()
  defrust collect_binding(record, claim, binding) do
    bound =
      case {binding.origin, binding.rank, bound_node_field(claim.field)} do
        {:assignment, {:some, rank}, {:some, field}} -> Map.put(record.bound, field, rank)
        _ -> record.bound
      end

    record = %{record | claims: record.claims ++ [claim.clone()], bound: bound}

    case claim.field do
      :symbol_data ->
        superseded =
          for value <- binding.superseded,
              {:some, guid} <- [guid_key(value.guid.as_ref())],
              do: guid

        %{record | superseded: superseded ++ record.superseded}

      :slot_content ->
        %{record | slot_content: binding.value.slot_content}

      _ ->
        record
    end
  end

  # The record field a binding sets, which an outer assignment keeps from inner claims.
  @spec bound_node_field(Occurrence.bound_field()) :: R.option(R.u32())
  defrust bound_node_field(field) do
    case field do
      :visible -> some(Kiwi.NodeChange.VISIBLE)
      :text_data -> some(Kiwi.NodeChange.TEXT_DATA)
      :symbol_data -> some(Kiwi.NodeChange.SYMBOL_DATA)
      :slot_content -> nil
    end
  end

  # Visibility an outer instance assigns counts as that instance's override.
  @spec assigned_visibility(R.slice(Occurrence.binding_claim())) :: HashSet.t(R.u32())
  defrust assigned_visibility(claims) do
    if Enum.any?(claims, &assigned_visible?/1),
      do: MapSet.new([Kiwi.NodeChange.VISIBLE]),
      else: MapSet.new()
  end

  @spec assigned_visible?(R.ref(Occurrence.binding_claim())) :: R.bool()
  defrust assigned_visible?(claim) do
    match?({:visible, :assignment}, {claim.field, claim.origin})
  end

  # A component and its override key both address the root of an expansion.
  @spec component_keys(R.ref(SourceIndex.source_index()), R.option(Records.guid_key())) ::
          R.vec(Records.guid_key())
  defrust component_keys(index, guid) do
    case guid do
      {:some, guid} ->
        case source(index, guid).and_then(fn record -> override_key(record) end) do
          {:some, key} -> [guid, key]
          :none -> [guid]
        end

      :none ->
        []
    end
  end

  # Root layers select the effective component and the full assignment list, inner to outer
  # so later entries win. Everything else addresses a descendant.
  @spec resolve_root(
          R.ref(SourceIndex.source_index()),
          R.ref(Kiwi.kiwi_record()),
          R.ref(bound_record()),
          R.vec(Layer.layer()),
          R.u32()
        ) :: R.nif_result(root())
  defrust resolve_root(index, raw, record, structural, rank) do
    original = symbol_id(raw)
    effective = symbol_id(record.source)
    keys = component_keys(index, original) ++ component_keys(index, effective)

    assignments =
      Enum.map(record.source.records(Kiwi.NodeChange.COMPONENT_PROP_ASSIGNMENTS), fn assignment ->
        assignment.clone()
      end)

    root =
      struct_literal(Root,
        effective: effective,
        replaced: replaced_before(original, effective, record.superseded),
        keys: keys,
        groups: [struct_literal(Group, assignments: assignments, rank: rank)],
        descendant: []
      )

    for layer <- structural do
      route_root_layer(index, mut_ref(root), layer)
    end

    ok(root)
  end

  # Components an occurrence would have expanded before outer bindings replaced them.
  @spec replaced_before(
          R.option(Records.guid_key()),
          R.option(Records.guid_key()),
          R.slice(Records.guid_key())
        ) ::
          R.vec(Records.guid_key())
  defrust replaced_before(original, effective, superseded) do
    case effective do
      {:some, effective} ->
        original
        |> into_iter()
        |> chain(superseded.iter().copied())
        |> filter(fn component -> deref(component) != effective end)
        |> collect()

      :none ->
        []
    end
  end

  @spec route_root_layer(R.ref(SourceIndex.source_index()), R.mut_ref(root()), Layer.layer()) ::
          R.nif_result(R.unit())
  defrust route_root_layer(index, root, layer) do
    case layer.path do
      [first | _rest] when first not in root.keys ->
        root.descendant.push(layer)
        ok(:ok)

      [_first, _second | _rest] ->
        root.descendant.push(descend(layer))
        ok(:ok)

      _ ->
        swap_root(index, root, layer.swap)

        if layer.assignments != [] do
          root.groups.push(
            struct_literal(Group, assignments: layer.assignments, rank: layer.owner.rank)
          )
        end

        ok(:ok)
    end
  end

  @spec swap_root(
          R.ref(SourceIndex.source_index()),
          R.mut_ref(root()),
          R.option(Records.guid_key())
        ) ::
          R.nif_result(R.unit())
  defrust swap_root(index, root, swap) do
    case {swap, root.effective} do
      {:none, _effective} ->
        ok(:ok)

      {{:some, _swap}, :none} ->
        err(badarg())

      {{:some, swap}, {:some, effective}} when swap == effective ->
        ok(:ok)

      {{:some, swap}, {:some, effective}} ->
        for key <- component_keys(index, some(swap)) do
          if key not in root.keys, do: root.keys.push(key)
        end

        root.replaced.push(effective)
        assign!(root.effective, some(swap))
        ok(:ok)
    end
  end

  # A component definition starts a binding scope from its defaults, which the instance's
  # assignment groups replace in order.
  @spec scoped_bindings(R.ref(Kiwi.kiwi_record()), R.slice(group())) :: R.vec(Bindings.binding())
  defrust scoped_bindings(source, groups) do
    defaults = component(source.records(Kiwi.NodeChange.COMPONENT_PROP_DEFS))

    Enum.reduce(groups, defaults, fn group, bindings ->
      assign(bindings, group.assignments.iter().collect(), some(group.rank))
    end)
  end

  # The component expansion receives the assignments as its own root layers and the
  # descendant layers unchanged: both address the same subtree.
  @spec expand_base(
          R.ref(SourceIndex.source_index()),
          R.ref(Layer.layer_owner()),
          R.ref(root()),
          R.u32(),
          R.mut_ref(state())
        ) :: R.nif_result({subtree(), R.vec(Occurrence.occurrence())})
  defrust expand_base(index, owner, root, rank, state) do
    component_id = root.effective.unwrap()

    if Map.has_key?(index.sources, component_id) do
      layers =
        root_layers(owner, root.groups) ++
          Enum.map(root.descendant, fn layer -> cross_boundary(layer, root.replaced) end)

      base = expand(index, component_id, [], layers, rank + 1, state)
      children = base.children

      ok({struct_literal(Subtree, base: some(%{base | children: []}), dangling: false), children})
    else
      state.diagnostics.push(
        struct_literal(Diagnostic,
          kind: :missing_component,
          owner: owner.id,
          component: some(component_id),
          path: [],
          reason: nil
        )
      )

      ok({struct_literal(Subtree, base: nil, dangling: true), []})
    end
  end

  @spec root_layers(R.ref(Layer.layer_owner()), R.slice(group())) :: R.vec(Layer.layer())
  defrust root_layers(owner, groups) do
    for group <- groups, group.assignments != [] do
      struct_literal(Layer,
        owner: struct_literal(LayerOwner, id: owner.id, rank: group.rank),
        declared_path: [],
        path: [],
        swap: nil,
        boundary: nil,
        assignments: group.assignments.clone()
      )
    end
  end

  @spec cross_boundary(R.ref(Layer.layer()), R.slice(Records.guid_key())) :: Layer.layer()
  defrust cross_boundary(layer, replaced) do
    if replaced == [] do
      layer.clone()
    else
      boundary = struct_literal(Boundary, replaced: replaced, path: layer.path.clone())
      %{layer.clone() | boundary: some(boundary)}
    end
  end

  @spec expand_children_of(
          R.ref(SourceIndex.source_index()),
          Records.guid_key(),
          R.slice(Bindings.binding()),
          R.slice(Layer.layer()),
          R.u32(),
          R.mut_ref(state())
        ) :: R.nif_result({subtree(), R.vec(Occurrence.occurrence())})
  defrust expand_children_of(index, id, bindings, descendant, rank, state) do
    routed = route_to_children(index, id, descendant, state)
    children = []

    for child_id <- children_of(index, id) do
      layers = routed.remove(child_id).unwrap_or_default()
      children.push(expand(index, child_id, bindings, layers, rank + 1, state))
    end

    ok({struct_literal(Subtree, base: nil, dangling: false), children})
  end

  # Dispatches structural layers to the direct child whose static subtree holds their first
  # segment.
  @spec route_to_children(
          R.ref(SourceIndex.source_index()),
          Records.guid_key(),
          R.slice(Layer.layer()),
          R.mut_ref(state())
        ) :: HashMap.t(Records.guid_key(), R.vec(Layer.layer()))
  defrust route_to_children(index, id, layers, state) do
    for layer <- layers, reduce: %{} do
      routed ->
        found = find_static_segment(index, id, layer.path[0])

        case found.top do
          {:some, top} ->
            routed_layer = routed_layer(index, top, layer)
            Map.update(routed, top, [routed_layer], fn found -> found ++ [routed_layer] end)

          :none ->
            unresolved_structural(index, layer, found.count, state)
            routed
        end
    end
  end

  @spec routed_layer(R.ref(SourceIndex.source_index()), Records.guid_key(), R.ref(Layer.layer())) ::
          Layer.layer()
  defrust routed_layer(index, top, layer) do
    if source(index, top).is_some_and(fn record -> matches?(record, layer.path[0]) end),
      do: descend(layer),
      else: layer.clone()
  end

  # A layer written against a component an outer decision replaced is stale, not wrong.
  # Anything else is reported once its owner is built.
  @spec unresolved_structural(
          R.ref(SourceIndex.source_index()),
          R.ref(Layer.layer()),
          R.usize(),
          R.mut_ref(state())
        ) :: R.unit()
  defrust unresolved_structural(index, layer, count, state) do
    if count != 0 or not stale_layer?(index, layer) do
      state.pending
      |> entry(layer.owner.id)
      |> or_default()
      |> push(struct_literal(Pending, path: layer.declared_path.clone(), reason: reason(count)))
    end
  end

  @spec stale_layer?(R.ref(SourceIndex.source_index()), R.ref(Layer.layer())) :: R.bool()
  defrust stale_layer?(index, layer) do
    case layer.boundary do
      {:some, boundary} ->
        Enum.any?(boundary.replaced, fn component ->
          resolves_in_source_component?(index, component, boundary.path)
        end)

      :none ->
        false
    end
  end

  @spec report_owner(R.mut_ref(state()), Records.guid_key(), R.option(Records.guid_key())) ::
          R.unit()
  defrust report_owner(state, id, main_component_id) do
    for pending <- state.pending.remove(ref(id)).unwrap_or_default() do
      state.diagnostics.push(
        struct_literal(Diagnostic,
          kind: :unresolved_assignment,
          owner: id,
          component: main_component_id,
          path: pending.path,
          reason: some(pending.reason)
        )
      )
    end
  end

  @spec create_occurrence(
          R.ref(SourceIndex.source_index()),
          Records.guid_key(),
          R.ref(Kiwi.kiwi_record()),
          R.ref(Kiwi.kiwi_record()),
          R.ref(root()),
          R.option(R.ref(Occurrence.occurrence())),
          R.vec(Occurrence.occurrence())
        ) :: Occurrence.occurrence()
  defrust create_occurrence(index, id, raw, source, root, base, children) do
    original = symbol_id(raw)

    occurrence =
      new_occurrence(id, effective_properties(index, source, base, original, root), children)

    occurrence = %{
      occurrence
      | source_component_id: original,
        source_component_override_key: Enum.at(component_keys(index, original), 1),
        override_key: override_key(source)
    }

    occurrence =
      case base do
        {:some, base} ->
          inherited = %{
            occurrence
            | main_component_id: base.main_component_id.or(some(base.source_id)),
              main_component_override_key: base.main_component_override_key.or(base.override_key),
              property_claims: base.property_claims.clone(),
              has_own_name:
                node_type(index, base.source_id) == some(Kiwi.NodeType.INSTANCE) and
                  base.has_own_name
          }

          rename_swapped(inherited, base, root.replaced)

        :none ->
          occurrence
      end

    name = default_instance_name(index, occurrence)
    %{occurrence | default_instance_name: name}
  end

  @spec new_occurrence(Records.guid_key(), Kiwi.kiwi_record(), R.vec(Occurrence.occurrence())) ::
          Occurrence.occurrence()
  defrust new_occurrence(id, properties, children) do
    struct_literal(Occurrence,
      source_id: id,
      override_key: nil,
      main_component_id: nil,
      main_component_override_key: nil,
      source_component_id: nil,
      source_component_override_key: nil,
      derived_size: nil,
      slot_content_id: nil,
      default_instance_name: nil,
      properties: properties,
      children: children,
      property_claims: [],
      binding_claims: [],
      layout_scale: 1.0,
      has_own_name: false,
      bound_fields: %{},
      replaced_components: [],
      overridden: MapSet.new()
    )
  end

  # The component's look carries over; its identity does not. A swapped root draws the
  # replacement's paint, so the old paint's style link goes with it.
  @spec effective_properties(
          R.ref(SourceIndex.source_index()),
          R.ref(Kiwi.kiwi_record()),
          R.option(R.ref(Occurrence.occurrence())),
          R.option(Records.guid_key()),
          R.ref(root())
        ) :: Kiwi.kiwi_record()
  defrust effective_properties(index, source, base, original, root) do
    placed =
      if base != nil and original != root.effective and
           source.enum_value(Kiwi.NodeChange.TYPE) == some(Kiwi.NodeType.INSTANCE) do
        source.drop([Kiwi.NodeChange.FILL_PAINTS, Kiwi.NodeChange.STYLE_ID_FOR_FILL])
      else
        source.clone()
      end

    base_properties =
      case base do
        {:some, base} -> base.properties.clone()
        :none -> KiwiRecord.new(Kiwi.Definitions.NODE_CHANGE)
      end

    properties =
      base_properties.drop(component_identity()).merge(placed)
      |> put_effective_symbol(root.effective, source)

    properties =
      case merge_variable_consumption(base_properties, source) do
        {:some, consumption} ->
          properties.put_record(Kiwi.NodeChange.PARAMETER_CONSUMPTION_MAP, consumption)

        :none ->
          properties
      end

    put_assignments(index, properties, source, root.groups)
  end

  @spec put_effective_symbol(
          Kiwi.kiwi_record(),
          R.option(Records.guid_key()),
          R.ref(Kiwi.kiwi_record())
        ) ::
          Kiwi.kiwi_record()
  defrust put_effective_symbol(properties, effective, source) do
    case {effective, source.record(Kiwi.NodeChange.SYMBOL_DATA)} do
      {{:some, effective}, {:some, symbol_data}} ->
        properties.put_record(
          Kiwi.NodeChange.SYMBOL_DATA,
          symbol_data.put_record(Kiwi.SymbolData.SYMBOL_ID, guid_record(effective))
        )

      _ ->
        properties
    end
  end

  @spec guid_record(Records.guid_key()) :: Kiwi.kiwi_record()
  defrust guid_record(guid) do
    {session_id, local_id} = guid

    KiwiRecord.new(Kiwi.Definitions.GUID)
    |> put_uint(Kiwi.Guid.SESSION_ID, session_id)
    |> put_uint(Kiwi.Guid.LOCAL_ID, local_id)
  end

  # A slot whose content frame is gone falls back to its component's content.
  @spec put_assignments(
          R.ref(SourceIndex.source_index()),
          Kiwi.kiwi_record(),
          R.ref(Kiwi.kiwi_record()),
          R.slice(group())
        ) :: Kiwi.kiwi_record()
  defrust put_assignments(index, properties, source, groups) do
    if source.enum_value(Kiwi.NodeChange.TYPE) == some(Kiwi.NodeType.INSTANCE) do
      assignments =
        for group <- groups,
            assignment <- group.assignments,
            not missing_slot_content?(index, assignment),
            do: assignment.clone()

      properties.put_records(Kiwi.NodeChange.COMPONENT_PROP_ASSIGNMENTS, assignments)
    else
      properties
    end
  end

  @spec missing_slot_content?(R.ref(SourceIndex.source_index()), R.ref(Kiwi.kiwi_record())) ::
          R.bool()
  defrust missing_slot_content?(index, assignment) do
    assignment.record(Kiwi.ComponentPropAssignment.VAR_VALUE)
    |> and_then(fn variable -> variable.record(Kiwi.VariableData.VALUE) end)
    |> and_then(fn value -> slot_content(value) end)
    |> is_some_and(fn content -> not Map.has_key?(index.sources, content) end)
  end

  # A swapped instance without a name of its own takes the replacement's default.
  @spec rename_swapped(
          Occurrence.occurrence(),
          R.ref(Occurrence.occurrence()),
          R.slice(Records.guid_key())
        ) ::
          Occurrence.occurrence()
  defrust rename_swapped(occurrence, base, replaced) do
    if replaced == [] or occurrence.has_own_name do
      occurrence
    else
      name =
        case base.default_instance_name do
          {:some, name} -> some(name.clone())
          :none -> base.properties.str(Kiwi.NodeChange.NAME).map(fn name -> name.to_string() end)
        end

      properties =
        case name do
          {:some, name} -> occurrence.properties.put_str(Kiwi.NodeChange.NAME, name)
          :none -> occurrence.properties.delete(Kiwi.NodeChange.NAME)
        end

      %{occurrence | properties: properties}
    end
  end

  # Variants inside a component set default to the set's name.
  @spec default_instance_name(R.ref(SourceIndex.source_index()), R.ref(Occurrence.occurrence())) ::
          R.option(String.t())
  defrust default_instance_name(index, occurrence) do
    parent =
      source(index, occurrence.source_id)
      |> and_then(fn record -> parent_id(record) end)
      |> and_then(fn parent -> source(index, parent) end)

    case parent do
      {:some, set}
      when node_type(index, occurrence.source_id) != some(Kiwi.NodeType.INSTANCE) and
             set.bool(Kiwi.NodeChange.IS_STATE_GROUP) == some(true) ->
        set.str(Kiwi.NodeChange.NAME).map(fn name -> name.to_string() end)

      _ ->
        occurrence.properties.str(Kiwi.NodeChange.NAME).map(fn name -> name.to_string() end)
    end
  end

  # Applies this owner's property layers, then placed geometry and saved caches.
  @spec finish_occurrence(
          R.ref(SourceIndex.source_index()),
          Occurrence.occurrence(),
          R.ref(subtree()),
          R.ref(Kiwi.kiwi_record()),
          R.vec(Layer.claim()),
          R.u32(),
          R.mut_ref(state())
        ) :: R.nif_result(Occurrence.occurrence())
  defrust finish_occurrence(index, occurrence, subtree, source, claims, rank, state) do
    # Claims change properties, never the subtree's shape, so its path lookups are shared.
    tables = %{}

    for claim <- claims do
      case resolve_claim_target(index, occurrence, claim.path, state, mut_ref(tables)) do
        {:some, target_path} ->
          apply_property_claim(mut_ref(occurrence), rank, target_path, claim)

        :none ->
          :ok
      end
    end

    scaled = apply_layout_scale(occurrence, source)

    placed =
      apply_placed_constraints(scaled, subtree.base.as_ref(), source) |> put_instance_size(source)

    if subtree.dangling,
      do: ok(placed),
      else: ok(apply_derived_bounds(index, placed, source, state))
  end

  # The size the file keeps for an instance is its own content laid out.
  @spec put_instance_size(Occurrence.occurrence(), R.ref(Kiwi.kiwi_record())) ::
          Occurrence.occurrence()
  defrust put_instance_size(occurrence, source) do
    case source.record(Kiwi.NodeChange.SIZE) do
      {:some, size}
      when source.enum_value(Kiwi.NodeChange.TYPE) == some(Kiwi.NodeType.INSTANCE) ->
        %{
          occurrence
          | properties: occurrence.properties.put_record(Kiwi.NodeChange.SIZE, size.clone()),
            derived_size: some(size.clone())
        }

      _ ->
        occurrence
    end
  end

  @spec apply_property_claim(
          R.mut_ref(Occurrence.occurrence()),
          R.u32(),
          R.slice(R.usize()),
          R.ref(Layer.claim())
        ) :: R.unit()
  defrust apply_property_claim(owner, owner_rank, target_path, claim) do
    retained = retained(claim.props, get_at(owner, target_path), owner_rank)

    if retained != [] do
      apply_claim(at_mut(owner, target_path), retained)

      owner.property_claims.push(
        struct_literal(PropertyClaim,
          declared_by: owner.source_id,
          path: claim.path.clone(),
          properties: retained
        )
      )
    end
  end

  @spec resolve_claim_target(
          R.ref(SourceIndex.source_index()),
          R.ref(Occurrence.occurrence()),
          R.slice(Records.guid_key()),
          R.mut_ref(state()),
          R.mut_ref(Occurrence.segment_tables())
        ) :: R.option(R.vec(R.usize()))
  defrust resolve_claim_target(index, owner, path, state, tables) do
    case resolve_path(owner, path, tables) do
      {:ok, target_path} ->
        some(target_path)

      {:error, {_segment, 0}} ->
        if not removed_target?(index, owner, path) do
          state.diagnostics.push(unresolved_property(owner, path, 0))
        end

        nil

      {:error, {_segment, count}} ->
        state.diagnostics.push(unresolved_property(owner, path, count))
        nil
    end
  end

  @spec unresolved_property(
          R.ref(Occurrence.occurrence()),
          R.slice(Records.guid_key()),
          R.usize()
        ) ::
          diagnostic()
  defrust unresolved_property(owner, path, count) do
    struct_literal(Diagnostic,
      kind: :unresolved_property,
      owner: owner.source_id,
      component: owner.main_component_id,
      path: path,
      reason: some(reason(count))
    )
  end

  # A claim that addressed a component an instance on its path no longer expands is stale:
  # an outer decision replaced that subtree.
  @spec removed_target?(
          R.ref(SourceIndex.source_index()),
          R.ref(Occurrence.occurrence()),
          R.slice(Records.guid_key())
        ) :: R.bool()
  defrust(removed_target?(index, owner, path), do: removed_from?(index, owner, path, 0))

  @spec removed_from?(
          R.ref(SourceIndex.source_index()),
          R.ref(Occurrence.occurrence()),
          R.slice(Records.guid_key()),
          R.usize()
        ) :: R.bool()
  defrust removed_from?(index, current, path, position) do
    rest = Enum.drop(path, position)

    case rest do
      [segment | _later] ->
        cond do
          Enum.any?(current.replaced_components, fn component ->
            resolves_in_source_component?(index, component, rest)
          end) ->
            true

          position == 0 and root_guid?(current, segment) ->
            removed_from?(index, current, path, position + 1)

          true ->
            case find_segment(current, segment) do
              {:ok, indexes} ->
                removed_from?(index, get_at(current, indexes), path, position + 1)

              {:error, _count} ->
                false
            end
        end

      [] ->
        false
    end
  end

  # Placed root bounds belong to the instance record, not to its derived data.
  @spec apply_derived_bounds(
          R.ref(SourceIndex.source_index()),
          Occurrence.occurrence(),
          R.ref(Kiwi.kiwi_record()),
          R.mut_ref(state())
        ) :: Occurrence.occurrence()
  defrust apply_derived_bounds(index, owner, source, state) do
    # Derived entries change properties, never the subtree's shape.
    tables = %{}

    for entry <- source.records(Kiwi.NodeChange.DERIVED_SYMBOL_DATA) do
      path = override_path(entry)

      if path != [] do
        case resolve_claim_target(index, owner, path, state, mut_ref(tables)) do
          {:some, target_path} when target_path != [] ->
            apply_derived_entry(at_mut(mut_ref(owner), target_path), entry)

          _ ->
            :ok
        end
      end
    end

    owner
  end

  @spec reason(R.usize()) :: target_reason()
  defrust reason(count) do
    if count == 0, do: :missing_target, else: :ambiguous_target
  end

  @spec node_type(R.ref(SourceIndex.source_index()), Records.guid_key()) :: R.option(R.u32())
  defrust node_type(index, id) do
    source(index, id).and_then(fn record -> record.enum_value(Kiwi.NodeChange.TYPE) end)
  end
end
