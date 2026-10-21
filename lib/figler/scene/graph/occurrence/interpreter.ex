defmodule Figler.Scene.Graph.Occurrence.Interpreter do
  @moduledoc """
  Expands source records into occurrence trees, resolving instances.

  This is a port of OpenPencil's occurrence-scoped instance interpreter
  (`packages/fig/src/instance-overrides/interpret.ts`). Figma's instance model
  reduces to three things:

    * an instance expands its component's subtree;
    * owners contribute layers, each a partial record at a path relative to
      that owner (`symbolOverrides`, `componentPropAssignments`);
    * where layers overlap, the outermost owner wins.

  Swaps and property assignments are structural layers. They are routed down
  to the instance they configure before it expands, so every occurrence
  expands once with its effective component and full assignment list. Every
  other override is a property claim, applied by its owner onto the built
  subtree, inner owners before outer ones. An explicit claim keeps a field
  unless a strictly outer owner assigned it. Saved derived data is a cache,
  applied last.

  Unresolvable overrides are reported as diagnostics instead of failing:

    * `{:unresolved_property, owner, main_component, path, reason}`
    * `{:unresolved_assignment, owner, main_component, path, reason}`
    * `{:missing_component, owner, component}`
    * `{:missing_slot_content, slot, content}`

  where `reason` is `:missing_target` or `:ambiguous_target`. Overrides that
  address a component an outer swap replaced are stale and dropped silently.
  """

  alias Figler.Scene.Graph.Occurrence
  alias Figler.Scene.Graph.Occurrence.Bindings
  alias Figler.Scene.Graph.Occurrence.Claims
  alias Figler.Scene.Graph.Occurrence.Fields
  alias Figler.Scene.Graph.Occurrence.Geometry
  alias Figler.Scene.Graph.Occurrence.GUID
  alias Figler.Scene.Graph.Occurrence.Layer
  alias Figler.Scene.Graph.Occurrence.SourceIndex

  @type diagnostic :: tuple()

  defmodule State do
    @moduledoc false
    defstruct [:index, expanding: MapSet.new(), diagnostics: [], pending: %{}]
  end

  defmodule Subtree do
    @moduledoc false
    # `dangling?` marks an instance whose component is gone: only the record
    # itself remains addressable.
    defstruct base: nil, children: [], dangling?: false
  end

  @doc """
  Interprets a page (`CANVAS`), component (`SYMBOL`), or instance record.

  Returns the occurrence tree and the diagnostics collected while expanding it.
  Slot content frames are left out of a page's children: they are read through
  the instance that assigns them.
  """
  @spec interpret(SourceIndex.t(), GUID.t()) :: {Occurrence.t(), [diagnostic()]}
  def interpret(%SourceIndex{} = index, root_id) do
    unless Map.has_key?(index.sources, root_id) do
      raise ArgumentError, "missing source node #{GUID.format(root_id)}"
    end

    {occurrence, state} = expand(root_id, [], [], 0, %State{index: index})
    {drop_slot_content(occurrence, index), Enum.reverse(state.diagnostics)}
  end

  defp drop_slot_content(occurrence, index) do
    if Map.get(index.sources[occurrence.source_id], :type) == :canvas do
      children =
        Enum.reject(occurrence.children, &Map.get(&1.properties, :is_slot_content, false))

      %{occurrence | children: children}
    else
      occurrence
    end
  end

  ## Expansion

  # Expands one source record. `layers` are structural layers addressed
  # relative to this expansion: an empty path configures the record itself.
  defp expand(id, bindings, layers, rank, state) do
    if MapSet.member?(state.expanding, id) do
      raise ArgumentError, "cyclic component expansion at #{GUID.format(id)}"
    end

    raw = Map.fetch!(state.index.sources, id)
    {record, state} = bind_record(raw, bindings, state)
    state = %{state | expanding: MapSet.put(state.expanding, id)}

    owner = %{id: id, rank: rank}
    {own_structural, own_claims} = Layer.own(record.source, owner)
    structural = Enum.sort_by(own_structural ++ layers, & &1.owner.rank, :desc)
    root = resolve_root(raw, record, structural, rank, state.index)

    {subtree, state} = expand_subtree(id, owner, record, bindings, root, rank, state)

    occurrence =
      id
      |> create_occurrence(raw, record.source, root, subtree, state.index)
      |> Map.merge(%{
        binding_claims: record.claims,
        slot_content_id: record.slot_content,
        bound_fields: record.bound,
        overridden: assigned_visibility(record.claims),
        replaced_components: if(subtree.base, do: root.replaced, else: [])
      })

    claims =
      if subtree.dangling?,
        do: Enum.filter(own_claims, &root_claim?(occurrence, &1)),
        else: own_claims

    {occurrence, state} =
      finish_occurrence(occurrence, subtree, record.source, claims, rank, state)

    state = report_owner(state, id, occurrence.main_component_id)
    {occurrence, %{state | expanding: MapSet.delete(state.expanding, id)}}
  end

  defp expand_subtree(id, owner, record, bindings, root, rank, state) do
    cond do
      root.effective ->
        expand_base(owner, root, rank, state)

      record.slot_content ->
        expand_children_of(record.slot_content, [], root.descendant, rank, state)

      Map.get(record.source, :type) == :symbol ->
        expand_children_of(
          id,
          scoped_bindings(record.source, root.groups),
          root.descendant,
          rank,
          state
        )

      true ->
        expand_children_of(id, bindings, root.descendant, rank, state)
    end
  end

  defp root_claim?(occurrence, %{path: [segment]}), do: Occurrence.root_guid?(occurrence, segment)
  defp root_claim?(_occurrence, _claim), do: false

  # Binds the record's fields from the enclosing component scope.
  defp bind_record(raw, bindings, state) do
    {source, bound_claims} = Bindings.bind(raw, bindings)

    record =
      Enum.reduce(
        bound_claims,
        %{source: source, claims: [], bound: %{}, superseded: [], slot_content: nil},
        &collect_binding/2
      )

    record = %{record | claims: Enum.reverse(record.claims)}

    if record.slot_content && not Map.has_key?(state.index.sources, record.slot_content) do
      diagnostic = {:missing_slot_content, SourceIndex.id(raw), record.slot_content}
      {%{record | slot_content: nil}, diagnose(state, diagnostic)}
    else
      {record, state}
    end
  end

  defp collect_binding({claim, binding}, record) do
    record = %{record | claims: [claim | record.claims]}

    record =
      if binding.origin == :assignment and binding.rank != nil,
        do: %{record | bound: Map.put(record.bound, claim.field, binding.rank)},
        else: record

    case claim.field do
      :symbol_data ->
        %{
          record
          | superseded: Enum.flat_map(binding.superseded, &superseded_guid/1) ++ record.superseded
        }

      :slot_content ->
        %{record | slot_content: Bindings.slot_content(binding.value)}

      _field ->
        record
    end
  end

  # Visibility an outer instance assigns counts as that instance's override.
  defp assigned_visibility(claims) do
    if Enum.any?(claims, &match?(%{field: :visible, origin: :assignment}, &1)),
      do: MapSet.new([:visible]),
      else: MapSet.new()
  end

  defp superseded_guid(%{guid_value: guid}) when guid != nil, do: [GUID.key(guid)]
  defp superseded_guid(_value), do: []

  # A component and its override key both address the root of an expansion.
  defp component_keys(_index, nil), do: []

  defp component_keys(index, guid) do
    key = index.sources |> Map.get(guid, %{}) |> Map.get(:override_key) |> GUID.override_key()
    if key, do: [guid, key], else: [guid]
  end

  # Root layers select the effective component and the full assignment list,
  # inner to outer so later entries win. Everything else addresses a descendant.
  defp resolve_root(raw, record, structural, rank, index) do
    original = SourceIndex.symbol_id(raw)
    effective = SourceIndex.symbol_id(record.source)

    initial = %{
      effective: effective,
      replaced: replaced_before(original, effective, record.superseded),
      keys: component_keys(index, original) ++ component_keys(index, effective),
      groups: [
        %{assignments: Map.get(record.source, :component_prop_assignments) || [], rank: rank}
      ],
      descendant: []
    }

    root = Enum.reduce(structural, initial, &route_root_layer(&1, &2, index))

    %{
      root
      | descendant: Enum.reverse(root.descendant),
        groups: Enum.reverse(root.groups),
        replaced: Enum.reverse(root.replaced)
    }
  end

  # Components an occurrence would have expanded before outer bindings replaced
  # them, kept in reverse until the root is resolved.
  defp replaced_before(_original, nil, _superseded), do: []

  defp replaced_before(original, effective, superseded) do
    (List.wrap(original) ++ superseded)
    |> Enum.reject(&(&1 == effective))
    |> Enum.reverse()
  end

  defp route_root_layer(%Layer{path: path} = layer, root, index) do
    case {path == [] or hd(path) in root.keys, path} do
      {false, _path} ->
        %{root | descendant: [layer | root.descendant]}

      {true, [_root, _next | _rest]} ->
        %{root | descendant: [Layer.descend(layer) | root.descendant]}

      {true, _root_only} ->
        root |> swap_root(layer.swap, index) |> add_group(layer)
    end
  end

  defp swap_root(root, nil, _index), do: root

  defp swap_root(%{effective: nil}, _swap, _index),
    do: raise(ArgumentError, "swap target is not an instance")

  defp swap_root(%{effective: swap} = root, swap, _index), do: root

  defp swap_root(root, swap, index) do
    keys = root.keys ++ Enum.reject(component_keys(index, swap), &(&1 in root.keys))
    %{root | effective: swap, replaced: [root.effective | root.replaced], keys: keys}
  end

  defp add_group(root, %Layer{assignments: []}), do: root

  defp add_group(root, layer),
    do: %{
      root
      | groups: [%{assignments: layer.assignments, rank: layer.owner.rank} | root.groups]
    }

  # A component definition starts a binding scope from its defaults, which the
  # instance's assignment groups replace in order.
  defp scoped_bindings(source, groups) do
    defaults = Bindings.component(Map.get(source, :component_prop_defs))
    Enum.reduce(groups, defaults, &Bindings.assign(&2, &1.assignments, &1.rank))
  end

  # The component expansion receives the assignments as its own root layers and
  # the descendant layers unchanged: both address the same subtree.
  defp expand_base(owner, %{effective: component_id} = root, rank, state) do
    if Map.has_key?(state.index.sources, component_id) do
      layers =
        root_layers(owner, root.groups) ++
          Enum.map(root.descendant, &cross_boundary(&1, root.replaced))

      {base, state} = expand(component_id, [], layers, rank + 1, state)
      {%Subtree{base: base, children: base.children}, state}
    else
      {%Subtree{dangling?: true}, diagnose(state, {:missing_component, owner.id, component_id})}
    end
  end

  defp root_layers(owner, groups) do
    for %{assignments: [_ | _] = assignments, rank: rank} <- groups do
      %Layer{owner: %{owner | rank: rank}, declared_path: [], path: [], assignments: assignments}
    end
  end

  defp cross_boundary(layer, []), do: layer

  defp cross_boundary(layer, replaced),
    do: %{layer | boundary: %{replaced: replaced, path: layer.path}}

  defp expand_children_of(id, bindings, descendant, rank, state) do
    {routed, state} = route_to_children(id, descendant, state)

    {children, state} =
      state.index
      |> SourceIndex.children(id)
      |> Enum.map_reduce(state, fn child, state ->
        child_id = SourceIndex.id(child)

        expand(
          child_id,
          bindings,
          routed |> Map.get(child_id, []) |> Enum.reverse(),
          rank + 1,
          state
        )
      end)

    {%Subtree{children: children}, state}
  end

  # Dispatches structural layers to the direct child whose static subtree holds
  # their first segment. Routed lists are built in reverse.
  defp route_to_children(id, layers, state) do
    Enum.reduce(layers, {%{}, state}, fn %Layer{path: [segment | _rest]} = layer,
                                         {routed, state} ->
      case SourceIndex.find_static_segment(state.index, id, segment) do
        %{top: nil, count: count} ->
          {routed, unresolved_structural(layer, count, state)}

        %{top: top} ->
          {Map.update(
             routed,
             SourceIndex.id(top),
             [routed_layer(top, layer)],
             &[routed_layer(top, layer) | &1]
           ), state}
      end
    end)
  end

  defp routed_layer(top, %Layer{path: [segment | _rest]} = layer) do
    if SourceIndex.matches?(top, segment), do: Layer.descend(layer), else: layer
  end

  # A layer written against a component an outer decision replaced is stale,
  # not wrong. Anything else is reported once its owner is built.
  defp unresolved_structural(layer, count, state) do
    if count == 0 and stale_layer?(layer, state.index) do
      state
    else
      diagnostic = %{path: layer.declared_path, reason: reason(count)}

      %{
        state
        | pending: Map.update(state.pending, layer.owner.id, [diagnostic], &[diagnostic | &1])
      }
    end
  end

  defp stale_layer?(%Layer{boundary: nil}, _index), do: false

  defp stale_layer?(%Layer{boundary: %{replaced: replaced, path: path}}, index),
    do: Enum.any?(replaced, &SourceIndex.resolves_in_source_component?(index, &1, path))

  defp report_owner(state, id, main_component_id) do
    {pending, rest} = Map.pop(state.pending, id, [])

    pending
    |> Enum.reverse()
    |> Enum.reduce(%{state | pending: rest}, fn %{path: path, reason: reason}, state ->
      diagnose(state, {:unresolved_assignment, id, main_component_id, path, reason})
    end)
  end

  ## Occurrence construction

  defp create_occurrence(id, raw, source, root, %Subtree{base: base, children: children}, index) do
    original = SourceIndex.symbol_id(raw)

    occurrence =
      struct!(
        Occurrence,
        [
          source_id: id,
          source_component_id: original,
          source_component_override_key: index |> component_keys(original) |> Enum.at(1),
          override_key: GUID.override_key(Map.get(source, :override_key)),
          properties: effective_properties(source, base, original, root, index),
          children: children
        ] ++ inherited_from_base(base, index)
      )

    occurrence
    |> rename_swapped(base, root.replaced)
    |> then(&%{&1 | default_instance_name: default_instance_name(&1, index)})
  end

  # The component's look carries over; its identity does not. A swapped root
  # draws the replacement's paint, so the old paint's style link goes with it.
  defp effective_properties(source, base, original, root, index) do
    placed =
      if base && original != root.effective && Map.get(source, :type) == :instance,
        do: Map.drop(source, [:fill_paints, :style_id_for_fill]),
        else: source

    base_properties = if base, do: base.properties, else: %{}

    base_properties
    |> Map.drop(Fields.component_identity())
    |> Map.merge(placed)
    |> put_effective_symbol(root.effective, source)
    |> Map.merge(Claims.merge_variable_consumption(base_properties, source))
    |> put_assignments(source, root.groups, index)
  end

  defp inherited_from_base(nil, _index), do: []

  defp inherited_from_base(base, index) do
    [
      main_component_id: base.main_component_id || base.source_id,
      main_component_override_key: base.main_component_override_key || base.override_key,
      property_claims: base.property_claims,
      has_own_name:
        Map.get(index.sources[base.source_id], :type) == :instance and base.has_own_name
    ]
  end

  # A swapped instance without a name of its own takes the replacement's default.
  defp rename_swapped(occurrence, nil, _replaced), do: occurrence
  defp rename_swapped(occurrence, _base, []), do: occurrence

  defp rename_swapped(%Occurrence{has_own_name: true} = occurrence, _base, _replaced),
    do: occurrence

  defp rename_swapped(occurrence, base, _replaced) do
    name = base.default_instance_name || Map.get(base.properties, :name)
    %{occurrence | properties: Map.put(occurrence.properties, :name, name)}
  end

  defp put_effective_symbol(properties, nil, _source), do: properties

  defp put_effective_symbol(properties, {session_id, local_id}, %{symbol_data: symbol_data})
       when symbol_data != nil do
    symbol_data = Map.put(symbol_data, :symbol_id, %{session_id: session_id, local_id: local_id})
    Map.put(properties, :symbol_data, symbol_data)
  end

  defp put_effective_symbol(properties, _effective, _source), do: properties

  # A slot whose content frame is gone falls back to its component's content.
  defp put_assignments(properties, %{type: :instance}, groups, index) do
    assignments =
      groups
      |> Enum.flat_map(& &1.assignments)
      |> Enum.reject(&missing_slot_content?(&1, index))

    Map.put(properties, :component_prop_assignments, assignments)
  end

  defp put_assignments(properties, _source, _groups, _index), do: properties

  defp missing_slot_content?(assignment, index) do
    content = Bindings.slot_content(get_in(assignment, [:var_value, :value]))
    content != nil and not Map.has_key?(index.sources, content)
  end

  # Variants inside a component set default to the set's name.
  defp default_instance_name(occurrence, index) do
    source = Map.get(index.sources, occurrence.source_id, %{})
    parent = Map.get(index.sources, SourceIndex.parent_id(source), %{})

    if Map.get(source, :type) != :instance and Map.get(parent, :is_state_group) == true,
      do: Map.get(parent, :name),
      else: Map.get(occurrence.properties, :name)
  end

  # Applies this owner's property layers, then placed geometry and saved caches.
  defp finish_occurrence(occurrence, subtree, source, claims, rank, state) do
    # Claims change properties, never the subtree's shape, so its path lookups are shared.
    {occurrence, state, _tables} =
      Enum.reduce(claims, {occurrence, state, %{}}, fn claim, {occurrence, state, tables} ->
        case resolve_claim_target(occurrence, claim.path, state, tables) do
          {:ok, target_path, state, tables} ->
            {apply_property_claim(occurrence, rank, target_path, claim), state, tables}

          {:skip, state, tables} ->
            {occurrence, state, tables}
        end
      end)

    occurrence =
      occurrence
      |> Geometry.apply_layout_scale(source)
      |> Geometry.apply_placed_constraints(subtree.base, source)
      |> put_instance_size(source)

    if subtree.dangling?,
      do: {occurrence, state},
      else: apply_derived_bounds(occurrence, source, state)
  end

  # The size the file keeps for an instance is its own content laid out.
  defp put_instance_size(occurrence, %{type: :instance, size: size}) when size != nil do
    %{occurrence | properties: Map.put(occurrence.properties, :size, size), derived_size: size}
  end

  defp put_instance_size(occurrence, _source), do: occurrence

  defp apply_property_claim(owner, owner_rank, target_path, claim) do
    retained =
      owner
      |> Occurrence.get_at(target_path)
      |> then(&Claims.retained(claim.props, &1, owner_rank))

    if map_size(retained) == 0 do
      owner
    else
      owner = Occurrence.update_at(owner, target_path, &Claims.apply(&1, retained))
      claim = %{declared_by: owner.source_id, path: claim.path, properties: retained}
      %{owner | property_claims: owner.property_claims ++ [claim]}
    end
  end

  defp resolve_claim_target(owner, path, state, tables) do
    case Occurrence.resolve_path(owner, path, tables) do
      {{:ok, target_path}, tables} ->
        {:ok, target_path, state, tables}

      {{:error, _segment, 0}, tables} ->
        if removed_target?(owner, path, state.index),
          do: {:skip, state, tables},
          else: {:skip, diagnose(state, unresolved_property(owner, path, 0)), tables}

      {{:error, _segment, count}, tables} ->
        {:skip, diagnose(state, unresolved_property(owner, path, count)), tables}
    end
  end

  defp unresolved_property(owner, path, count),
    do: {:unresolved_property, owner.source_id, owner.main_component_id, path, reason(count)}

  # A claim that addressed a component an instance on its path no longer
  # expands is stale: an outer decision replaced that subtree.
  defp removed_target?(owner, path, index) do
    path
    |> Enum.with_index()
    |> Enum.reduce_while(owner, &step_removed_target(&1, &2, path, index))
    |> Kernel.==(:removed)
  end

  defp step_removed_target({segment, position}, current, path, index) do
    rest = Enum.drop(path, position)

    cond do
      Enum.any?(
        current.replaced_components,
        &SourceIndex.resolves_in_source_component?(index, &1, rest)
      ) ->
        {:halt, :removed}

      position == 0 and Occurrence.root_guid?(current, segment) ->
        {:cont, current}

      true ->
        next_segment(current, segment)
    end
  end

  defp next_segment(current, segment) do
    case Occurrence.find_segment(current, segment) do
      {:ok, indexes} -> {:cont, Occurrence.get_at(current, indexes)}
      {:error, _count} -> {:halt, :present}
    end
  end

  # Placed root bounds belong to the instance record, not to its derived data.
  defp apply_derived_bounds(owner, source, state) do
    source
    |> Map.get(:derived_symbol_data)
    |> List.wrap()
    |> Enum.reduce({owner, state, %{}}, fn entry, {owner, state, tables} ->
      case entry |> get_in([:guid_path, :guids]) |> List.wrap() |> Enum.map(&GUID.key/1) do
        [] -> {owner, state, tables}
        path -> apply_derived_entry(owner, path, entry, state, tables)
      end
    end)
    |> then(fn {owner, state, _tables} -> {owner, state} end)
  end

  # Derived entries change properties, never the subtree's shape.
  defp apply_derived_entry(owner, path, entry, state, tables) do
    case resolve_claim_target(owner, path, state, tables) do
      {:ok, [], state, tables} ->
        {owner, state, tables}

      {:ok, target_path, state, tables} ->
        owner = Occurrence.update_at(owner, target_path, &Geometry.apply_derived_entry(&1, entry))
        {owner, state, tables}

      {:skip, state, tables} ->
        {owner, state, tables}
    end
  end

  defp reason(0), do: :missing_target
  defp reason(_count), do: :ambiguous_target

  defp diagnose(state, diagnostic), do: %{state | diagnostics: [diagnostic | state.diagnostics]}
end
