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
           required(:owner) => GuidKey.t(),
           required(:component) => R.option(GuidKey.t()),
           required(:path) => R.vec(GuidKey.t()),
           required(:reason) => R.option(target_reason())
         }

  @typep pending :: %{required(:path) => R.vec(GuidKey.t()), required(:reason) => target_reason()}

  @typep state :: %{
           required(:expanding) => HashSet.t(GuidKey.t()),
           required(:diagnostics) => R.vec(diagnostic()),
           required(:pending) => HashMap.t(GuidKey.t(), R.vec(pending()))
         }

  # A record bound from its enclosing component scope.
  @typep bound_record :: %{
           required(:source) => Kiwi.kiwi_record(),
           required(:claims) => R.vec(Occurrence.binding_claim()),
           required(:bound) => HashMap.t(R.u32(), R.u32()),
           required(:superseded) => R.vec(GuidKey.t()),
           required(:slot_content) => R.option(GuidKey.t())
         }

  @typep group :: %{
           required(:assignments) => R.vec(Kiwi.kiwi_record()),
           required(:rank) => R.u32()
         }

  # The component an occurrence expands and the layers left for its descendants.
  @typep root :: %{
           required(:effective) => R.option(GuidKey.t()),
           required(:replaced) => R.vec(GuidKey.t()),
           required(:keys) => R.vec(GuidKey.t()),
           required(:groups) => R.vec(group()),
           required(:descendant) => R.vec(Layer.layer())
         }

  # The component expansion an occurrence's children come from. `dangling` marks an instance
  # whose component is gone: only the record itself remains addressable.
  @typep subtree :: %{
           required(:base) => R.option(Occurrence.occurrence()),
           required(:dangling) => R.bool()
         }

  @doc false
  @spec items() :: [term()]
  def items do
    __rustq_type_items__() ++
      RustQ.Meta.AST.functions!(__MODULE__, [
        :interpret,
        :drop_slot_content,
        :expand,
        :expand_source,
        :expand_subtree,
        :root_claim?,
        :bind_record,
        :collect_binding,
        :bound_node_field,
        :assigned_visibility,
        :assigned_visible?,
        :component_keys,
        :resolve_root,
        :replaced_before,
        :route_root_layer,
        :swap_root,
        :scoped_bindings,
        :expand_base,
        :root_layers,
        :cross_boundary,
        :expand_children_of,
        :route_to_children,
        :routed_layer,
        :unresolved_structural,
        :stale_layer?,
        :report_owner,
        :create_occurrence,
        :effective_properties,
        :put_effective_symbol,
        :guid_record,
        :put_assignments,
        :missing_slot_content?,
        :rename_swapped,
        :default_instance_name,
        :finish_occurrence,
        :put_instance_size,
        :apply_property_claim,
        :resolve_claim_target,
        :unresolved_property,
        :removed_target?,
        :removed_from?,
        :apply_derived_bounds,
        :reason,
        :node_type,
        :new_occurrence
      ])
  end

  # Interprets a page, component, or instance record: the occurrence tree and the diagnostics
  # collected while expanding it. Slot content frames are left out of a page's children: they
  # are read through the instance that assigns them.
  @spec interpret(R.ref(SourceIndex.source_index()), GuidKey.t()) ::
          R.nif_result({Occurrence.occurrence(), R.vec(diagnostic())})
  defrust interpret(index, root_id) do
    state =
      struct_literal(State,
        expanding: HashSet.new(),
        diagnostics: Vec.new(),
        pending: HashMap.new()
      )

    occurrence = expand(index, root_id, ref([]), Vec.new(), 0, mut_ref(state))
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
          GuidKey.t(),
          R.slice(Bindings.binding()),
          R.vec(Layer.layer()),
          R.u32(),
          R.mut_ref(state())
        ) :: R.nif_result(Occurrence.occurrence())
  defrust expand(index, id, bindings, layers, rank, state) do
    case source(index, id) do
      {:some, raw} when not state.expanding.contains(ref(id)) ->
        expand_source(index, id, raw, bindings, layers, rank, state)

      _ ->
        err(badarg())
    end
  end

  @spec expand_source(
          R.ref(SourceIndex.source_index()),
          GuidKey.t(),
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
    {structural, own_claims} = own(ref(record.source), owner.clone())
    structural.extend(layers)
    structural.sort_by(fn left, right -> right.owner.rank.cmp(ref(left.owner.rank)) end)
    root = resolve_root(index, raw, ref(record), structural, rank)

    {subtree, children} =
      expand_subtree(index, ref(owner), ref(record), bindings, ref(root), rank, state)

    base = subtree.base.as_ref()

    occurrence =
      create_occurrence(index, id, raw, ref(record.source), ref(root), base, children)

    occurrence = %{
      occurrence
      | binding_claims: record.claims.clone(),
        slot_content_id: record.slot_content,
        bound_fields: record.bound.clone(),
        overridden: assigned_visibility(ref(record.claims)),
        replaced_components: if(base.is_some(), do: root.replaced.clone(), else: Vec.new())
    }

    claims =
      if subtree.dangling,
        do: for(claim <- own_claims, root_claim?(ref(occurrence), ref(claim)), do: claim),
        else: own_claims

    occurrence =
      finish_occurrence(index, occurrence, ref(subtree), ref(record.source), claims, rank, state)

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
    cond do
      root.effective.is_some() ->
        expand_base(index, owner, root, rank, state)

      record.slot_content.is_some() ->
        expand_children_of(
          index,
          record.slot_content.unwrap(),
          ref([]),
          ref(root.descendant),
          rank,
          state
        )

      record.source.enum_value(Kiwi.NodeChange.TYPE) == some(Kiwi.NodeType.SYMBOL) ->
        expand_children_of(
          index,
          owner.id,
          scoped_bindings(ref(record.source), ref(root.groups)),
          ref(root.descendant),
          rank,
          state
        )

      true ->
        expand_children_of(index, owner.id, bindings, ref(root.descendant), rank, state)
    end
  end

  @spec root_claim?(R.ref(Occurrence.occurrence()), R.ref(Layer.claim())) :: R.bool()
  defrust root_claim?(occurrence, claim) do
    claim.path.len() == 1 and root_guid?(occurrence, claim.path[0])
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

    record =
      bound_claims
      |> iter()
      |> fold(
        struct_literal(BoundRecord,
          source: source,
          claims: Vec.new(),
          bound: HashMap.new(),
          superseded: Vec.new(),
          slot_content: nil
        ),
        fn record, {claim, binding} -> collect_binding(record, claim, binding) end
      )

    case record.slot_content do
      {:some, content} when not index.sources.contains_key(ref(content)) ->
        state.diagnostics.push(
          struct_literal(Diagnostic,
            kind: :missing_slot_content,
            owner: record_id(raw).unwrap_or_default(),
            component: some(content),
            path: Vec.new(),
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
    record.claims.push(claim.clone())

    case {binding.origin, binding.rank, bound_node_field(claim.field)} do
      {:assignment, {:some, rank}, {:some, field}} -> record.bound.insert(field, rank)
      _ -> nil
    end

    case claim.field do
      :symbol_data ->
        superseded =
          binding.superseded
          |> iter()
          |> filter_map(fn value ->
            value.guid.as_ref().and_then(fn guid -> guid_key(some(guid)) end)
          end)
          |> collect()

        superseded.extend(record.superseded)
        %{record | superseded: superseded}

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
    overridden = HashSet.new()

    if claims.iter().any(fn claim -> assigned_visible?(claim) end),
      do: overridden.insert(Kiwi.NodeChange.VISIBLE)

    overridden
  end

  @spec assigned_visible?(R.ref(Occurrence.binding_claim())) :: R.bool()
  defrust assigned_visible?(claim) do
    match?({:visible, :assignment}, {claim.field, claim.origin})
  end

  # A component and its override key both address the root of an expansion.
  @spec component_keys(R.ref(SourceIndex.source_index()), R.option(GuidKey.t())) ::
          R.vec(GuidKey.t())
  defrust component_keys(index, guid) do
    case guid do
      {:some, guid} ->
        case source(index, guid).and_then(fn record -> override_key(record) end) do
          {:some, key} -> [guid, key]
          :none -> [guid]
        end

      :none ->
        Vec.new()
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
    effective = symbol_id(ref(record.source))
    keys = component_keys(index, original)
    keys.extend(component_keys(index, effective))

    assignments =
      record.source.records(Kiwi.NodeChange.COMPONENT_PROP_ASSIGNMENTS)
      |> into_iter()
      |> cloned()
      |> collect()

    root =
      struct_literal(Root,
        effective: effective,
        replaced: replaced_before(original, effective, ref(record.superseded)),
        keys: keys,
        groups: [struct_literal(Group, assignments: assignments, rank: rank)],
        descendant: Vec.new()
      )

    for layer <- structural do
      route_root_layer(index, mut_ref(root), layer)
    end

    ok(root)
  end

  # Components an occurrence would have expanded before outer bindings replaced them.
  @spec replaced_before(R.option(GuidKey.t()), R.option(GuidKey.t()), R.slice(GuidKey.t())) ::
          R.vec(GuidKey.t())
  defrust replaced_before(original, effective, superseded) do
    case effective do
      {:some, effective} ->
        original
        |> into_iter()
        |> chain(superseded.iter().copied())
        |> filter(fn component -> deref(component) != effective end)
        |> collect()

      :none ->
        Vec.new()
    end
  end

  @spec route_root_layer(R.ref(SourceIndex.source_index()), R.mut_ref(root()), Layer.layer()) ::
          R.nif_result(R.unit())
  defrust route_root_layer(index, root, layer) do
    at_root =
      case layer.path.first() do
        {:some, first} -> root.keys.contains(first)
        :none -> true
      end

    cond do
      not at_root ->
        root.descendant.push(layer)
        ok(:ok)

      layer.path.len() >= 2 ->
        root.descendant.push(descend(ref(layer)))
        ok(:ok)

      true ->
        swap_root(index, root, layer.swap)

        if not layer.assignments.is_empty() do
          root.groups.push(
            struct_literal(Group, assignments: layer.assignments, rank: layer.owner.rank)
          )
        end

        ok(:ok)
    end
  end

  @spec swap_root(R.ref(SourceIndex.source_index()), R.mut_ref(root()), R.option(GuidKey.t())) ::
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
          if not root.keys.contains(ref(key)), do: root.keys.push(key)
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
    groups
    |> iter()
    |> fold(component(source.records(Kiwi.NodeChange.COMPONENT_PROP_DEFS)), fn bindings, group ->
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

    if index.sources.contains_key(ref(component_id)) do
      layers = root_layers(owner, ref(root.groups))

      layers.extend(
        root.descendant
        |> iter()
        |> map(fn layer -> cross_boundary(layer, ref(root.replaced)) end)
      )

      base = expand(index, component_id, ref([]), layers, rank + 1, state)
      children = base.children

      ok(
        {struct_literal(Subtree, base: some(%{base | children: Vec.new()}), dangling: false),
         children}
      )
    else
      state.diagnostics.push(
        struct_literal(Diagnostic,
          kind: :missing_component,
          owner: owner.id,
          component: some(component_id),
          path: Vec.new(),
          reason: nil
        )
      )

      ok({struct_literal(Subtree, base: nil, dangling: true), Vec.new()})
    end
  end

  @spec root_layers(R.ref(Layer.layer_owner()), R.slice(group())) :: R.vec(Layer.layer())
  defrust root_layers(owner, groups) do
    for group <- groups, not group.assignments.is_empty() do
      struct_literal(Layer,
        owner: struct_literal(LayerOwner, id: owner.id, rank: group.rank),
        declared_path: Vec.new(),
        path: Vec.new(),
        swap: nil,
        boundary: nil,
        assignments: group.assignments.clone()
      )
    end
  end

  @spec cross_boundary(R.ref(Layer.layer()), R.slice(GuidKey.t())) :: Layer.layer()
  defrust cross_boundary(layer, replaced) do
    if replaced.is_empty() do
      layer.clone()
    else
      boundary = struct_literal(Boundary, replaced: replaced.to_vec(), path: layer.path.clone())
      %{layer.clone() | boundary: some(boundary)}
    end
  end

  @spec expand_children_of(
          R.ref(SourceIndex.source_index()),
          GuidKey.t(),
          R.slice(Bindings.binding()),
          R.slice(Layer.layer()),
          R.u32(),
          R.mut_ref(state())
        ) :: R.nif_result({subtree(), R.vec(Occurrence.occurrence())})
  defrust expand_children_of(index, id, bindings, descendant, rank, state) do
    routed = route_to_children(index, id, descendant, state)
    children = Vec.new()

    for child_id <- children_of(index, id) do
      layers = routed.remove(child_id).unwrap_or_default()
      children.push(expand(index, deref(child_id), bindings, layers, rank + 1, state))
    end

    ok({struct_literal(Subtree, base: nil, dangling: false), children})
  end

  # Dispatches structural layers to the direct child whose static subtree holds their first
  # segment.
  @spec route_to_children(
          R.ref(SourceIndex.source_index()),
          GuidKey.t(),
          R.slice(Layer.layer()),
          R.mut_ref(state())
        ) :: HashMap.t(GuidKey.t(), R.vec(Layer.layer()))
  defrust route_to_children(index, id, layers, state) do
    routed = HashMap.new()

    for layer <- layers do
      found = find_static_segment(index, id, layer.path[0])

      case found.top do
        {:some, top} ->
          routed.entry(top).or_default().push(routed_layer(index, top, layer))

        :none ->
          unresolved_structural(index, layer, found.count, state)
      end
    end

    routed
  end

  @spec routed_layer(R.ref(SourceIndex.source_index()), GuidKey.t(), R.ref(Layer.layer())) ::
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
    case ref(layer.boundary) do
      {:some, boundary} ->
        boundary.replaced
        |> iter()
        |> any(fn component ->
          resolves_in_source_component?(index, deref(component), ref(boundary.path))
        end)

      :none ->
        false
    end
  end

  @spec report_owner(R.mut_ref(state()), GuidKey.t(), R.option(GuidKey.t())) :: R.unit()
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
          GuidKey.t(),
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
        source_component_override_key: component_keys(index, original).get(1).copied(),
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

          rename_swapped(inherited, base, ref(root.replaced))

        :none ->
          occurrence
      end

    name = default_instance_name(index, ref(occurrence))
    %{occurrence | default_instance_name: name}
  end

  @spec new_occurrence(GuidKey.t(), Kiwi.kiwi_record(), R.vec(Occurrence.occurrence())) ::
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
      property_claims: Vec.new(),
      binding_claims: Vec.new(),
      layout_scale: 1.0,
      has_own_name: false,
      bound_fields: HashMap.new(),
      replaced_components: Vec.new(),
      overridden: HashSet.new()
    )
  end

  # The component's look carries over; its identity does not. A swapped root draws the
  # replacement's paint, so the old paint's style link goes with it.
  @spec effective_properties(
          R.ref(SourceIndex.source_index()),
          R.ref(Kiwi.kiwi_record()),
          R.option(R.ref(Occurrence.occurrence())),
          R.option(GuidKey.t()),
          R.ref(root())
        ) :: Kiwi.kiwi_record()
  defrust effective_properties(index, source, base, original, root) do
    placed =
      if base.is_some() and original != root.effective and
           source.enum_value(Kiwi.NodeChange.TYPE) == some(Kiwi.NodeType.INSTANCE) do
        source.drop(ref([Kiwi.NodeChange.FILL_PAINTS, Kiwi.NodeChange.STYLE_ID_FOR_FILL]))
      else
        source.clone()
      end

    base_properties =
      case base do
        {:some, base} -> base.properties.clone()
        :none -> KiwiRecord.new(Kiwi.Definitions.NODE_CHANGE)
      end

    properties =
      base_properties.drop(component_identity()).merge(ref(placed))
      |> put_effective_symbol(root.effective, source)

    properties =
      case merge_variable_consumption(ref(base_properties), source) do
        {:some, consumption} ->
          properties.put_record(Kiwi.NodeChange.PARAMETER_CONSUMPTION_MAP, consumption)

        :none ->
          properties
      end

    put_assignments(index, properties, source, ref(root.groups))
  end

  @spec put_effective_symbol(Kiwi.kiwi_record(), R.option(GuidKey.t()), R.ref(Kiwi.kiwi_record())) ::
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

  @spec guid_record(GuidKey.t()) :: Kiwi.kiwi_record()
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
            assignment <- group.assignments.iter(),
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
    |> is_some_and(fn content -> not index.sources.contains_key(ref(content)) end)
  end

  # A swapped instance without a name of its own takes the replacement's default.
  @spec rename_swapped(
          Occurrence.occurrence(),
          R.ref(Occurrence.occurrence()),
          R.slice(GuidKey.t())
        ) ::
          Occurrence.occurrence()
  defrust rename_swapped(occurrence, base, replaced) do
    if replaced.is_empty() or occurrence.has_own_name do
      occurrence
    else
      name =
        case ref(base.default_instance_name) do
          {:some, name} -> some(name.clone())
          :none -> base.properties.str(Kiwi.NodeChange.NAME).map(fn name -> name.to_string() end)
        end

      properties =
        case name do
          {:some, name} -> occurrence.properties.put_str(Kiwi.NodeChange.NAME, ref(name))
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
    tables = HashMap.new()

    for claim <- claims.iter() do
      case resolve_claim_target(index, ref(occurrence), ref(claim.path), state, mut_ref(tables)) do
        {:some, target_path} ->
          apply_property_claim(mut_ref(occurrence), rank, ref(target_path), claim)

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
    retained = retained(ref(claim.props), get_at(owner, target_path), owner_rank)

    if not retained.is_empty() do
      apply_claim(at_mut(owner, target_path), ref(retained))

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
          R.slice(GuidKey.t()),
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

  @spec unresolved_property(R.ref(Occurrence.occurrence()), R.slice(GuidKey.t()), R.usize()) ::
          diagnostic()
  defrust unresolved_property(owner, path, count) do
    struct_literal(Diagnostic,
      kind: :unresolved_property,
      owner: owner.source_id,
      component: owner.main_component_id,
      path: path.to_vec(),
      reason: some(reason(count))
    )
  end

  # A claim that addressed a component an instance on its path no longer expands is stale:
  # an outer decision replaced that subtree.
  @spec removed_target?(
          R.ref(SourceIndex.source_index()),
          R.ref(Occurrence.occurrence()),
          R.slice(GuidKey.t())
        ) :: R.bool()
  defrust(removed_target?(index, owner, path), do: removed_from?(index, owner, path, 0))

  @spec removed_from?(
          R.ref(SourceIndex.source_index()),
          R.ref(Occurrence.occurrence()),
          R.slice(GuidKey.t()),
          R.usize()
        ) :: R.bool()
  defrust removed_from?(index, current, path, position) do
    case path.get(position) do
      {:some, segment} ->
        rest = path.iter().skip(position).copied().collect()

        cond do
          current.replaced_components
          |> iter()
          |> any(fn component ->
            resolves_in_source_component?(index, deref(component), ref(rest))
          end) ->
            true

          position == 0 and root_guid?(current, deref(segment)) ->
            removed_from?(index, current, path, position + 1)

          true ->
            case find_segment(current, deref(segment)) do
              {:ok, indexes} ->
                removed_from?(index, get_at(current, ref(indexes)), path, position + 1)

              {:error, _count} ->
                false
            end
        end

      :none ->
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
    tables = HashMap.new()

    for entry <- source.records(Kiwi.NodeChange.DERIVED_SYMBOL_DATA) do
      path = override_path(entry)

      if not path.is_empty() do
        case resolve_claim_target(index, ref(owner), ref(path), state, mut_ref(tables)) do
          {:some, target_path} when not target_path.is_empty() ->
            apply_derived_entry(at_mut(mut_ref(owner), ref(target_path)), entry)

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

  @spec node_type(R.ref(SourceIndex.source_index()), GuidKey.t()) :: R.option(R.u32())
  defrust node_type(index, id) do
    source(index, id).and_then(fn record -> record.enum_value(Kiwi.NodeChange.TYPE) end)
  end
end
