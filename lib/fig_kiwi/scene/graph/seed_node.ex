# credo:disable-for-this-file Credo.Check.Warning.StructFieldAmount

defmodule FigKiwi.Scene.Graph.SeedNode do
  @moduledoc """
  Raw projected node plus graph-resolver metadata.

  A seed node is the input to `FigKiwi.Scene.Graph` resolution. It is not the
  final effective node: resolver stages may clone it, patch fields, or attach
  provenance. Override-related fields are intentionally structured even when
  currently empty so the Elixir resolver can grow without changing public shape.
  """

  alias FigKiwi.Scene.Graph.ComponentPropAssignment
  alias FigKiwi.Scene.Graph.ComponentPropDef
  alias FigKiwi.Scene.Graph.ComponentPropRef
  alias FigKiwi.Scene.Graph.DerivedSymbolData
  alias FigKiwi.Scene.Graph.GUID
  alias FigKiwi.Scene.Graph.SymbolOverride
  alias FigKiwi.Scene.Node

  @enforce_keys [:guid, :node_type]
  defstruct [
    :guid,
    :node_type,
    :name,
    :parent_guid,
    :position,
    :size,
    :transform,
    :visible,
    :locked,
    :text,
    :font_family,
    :font_style,
    :font_postscript,
    :text_style_guid,
    :component_key,
    :origin_component_key,
    :fill_style_guid,
    :stroke_style_guid,
    :effect_style_guid,
    :grid_style_guid,
    :fill_count,
    :stroke_count,
    :component_guid,
    :symbol_id,
    :override_key,
    origin: :source,
    symbol_overrides: [],
    component_prop_defs: [],
    component_prop_refs: [],
    component_prop_assignments: [],
    derived_symbol_data: [],
    variable_consumption: [],
    variable_data_values: [],
    source: nil
  ]

  @type t :: %__MODULE__{
          guid: GUID.graph_guid(),
          node_type: String.t(),
          name: String.t() | nil,
          parent_guid: GUID.graph_guid() | nil,
          position: String.t() | nil,
          size: map() | nil,
          transform: map() | nil,
          visible: boolean() | nil,
          locked: boolean() | nil,
          text: String.t() | nil,
          font_family: String.t() | nil,
          font_style: String.t() | nil,
          font_postscript: String.t() | nil,
          text_style_guid: String.t() | nil,
          component_key: String.t() | nil,
          origin_component_key: String.t() | nil,
          fill_style_guid: String.t() | nil,
          stroke_style_guid: String.t() | nil,
          effect_style_guid: String.t() | nil,
          grid_style_guid: String.t() | nil,
          fill_count: non_neg_integer() | nil,
          stroke_count: non_neg_integer() | nil,
          component_guid: GUID.figma_guid() | nil,
          symbol_id: GUID.figma_guid() | nil,
          override_key: GUID.figma_guid() | nil,
          origin: :source | :clone,
          symbol_overrides: [SymbolOverride.t()],
          component_prop_defs: [ComponentPropDef.t()],
          component_prop_refs: [ComponentPropRef.t()],
          component_prop_assignments: [ComponentPropAssignment.t()],
          derived_symbol_data: [DerivedSymbolData.t()],
          variable_consumption: [term()],
          variable_data_values: [term()],
          source: Node.t() | map() | nil
        }

  @doc """
  Builds seed nodes from a decoded generated `Message` struct.
  """
  @spec from_message(FigKiwi.Schema.Message.t() | map(), keyword()) :: [t()]
  def from_message(message, opts \\ [])

  def from_message(%{node_changes: node_changes}, opts) when is_list(node_changes) do
    node_changes
    |> focused_node_changes(Keyword.get(opts, :focus))
    |> Enum.map(&from_node_change/1)
  end

  @doc """
  Builds a seed node from a generated `NodeChange` struct, including initial
  graph resolver metadata.
  """
  @spec from_node_change(FigKiwi.Schema.NodeChange.t() | map()) :: t()
  def from_node_change(node_change) when is_map(node_change) do
    symbol_data = get(node_change, :symbol_data)
    symbol_id = guid(symbol_data && get(symbol_data, :symbol_id))
    node = public_node_from_change(node_change)

    %__MODULE__{
      from_node(node)
      | symbol_id: symbol_id,
        override_key: guid(get(node_change, :override_key)),
        component_guid: symbol_id,
        symbol_overrides: symbol_overrides(symbol_data),
        component_prop_defs: component_prop_defs(get(node_change, :component_prop_defs)),
        component_prop_refs: component_prop_refs(get(node_change, :component_prop_refs)),
        component_prop_assignments:
          component_prop_assignments(get(node_change, :component_prop_assignments)),
        derived_symbol_data: derived_symbol_data(get(node_change, :derived_symbol_data)),
        variable_consumption: multiplayer_entries(get(node_change, :variable_consumption_map)),
        variable_data_values: multiplayer_entries(get(node_change, :variable_data_values))
    }
  end

  @doc """
  Builds a seed node from the current projected scene node.
  """
  @spec from_node(Node.t()) :: t()
  def from_node(%Node{} = node) do
    %__MODULE__{
      guid: GUID.parse!(node.guid),
      node_type: node.node_type,
      name: node.name,
      parent_guid: GUID.parse(node.parent_guid),
      position: node.position,
      size: node.size,
      transform: node.transform,
      visible: node.visible,
      locked: node.locked,
      text: node.text,
      font_family: node.font_family,
      font_style: node.font_style,
      font_postscript: node.font_postscript,
      text_style_guid: node.text_style_guid,
      component_key: node.component_key,
      origin_component_key: node.origin_component_key,
      fill_style_guid: node.fill_style_guid,
      stroke_style_guid: node.stroke_style_guid,
      effect_style_guid: node.effect_style_guid,
      grid_style_guid: node.grid_style_guid,
      fill_count: node.fill_count,
      stroke_count: node.stroke_count,
      source: node
    }
  end

  @doc """
  Builds a cloned seed node.
  """
  @spec clone(t() | nil, GUID.graph_guid(), GUID.graph_guid()) :: t() | nil
  def clone(nil, _clone_guid, _parent_guid), do: nil

  def clone(%__MODULE__{} = seed, clone_guid, parent_guid) do
    %__MODULE__{seed | guid: clone_guid, parent_guid: parent_guid, origin: :clone, source: seed}
  end

  @doc """
  Converts a seed node back to the public projected node struct.
  """
  @spec to_node(t()) :: Node.t()
  def to_node(%__MODULE__{} = seed) do
    %Node{
      guid: GUID.format(seed.guid),
      node_type: seed.node_type,
      name: seed.name,
      parent_guid: GUID.format(seed.parent_guid),
      position: seed.position,
      size: seed.size,
      transform: seed.transform,
      visible: seed.visible,
      locked: seed.locked,
      text: seed.text,
      font_family: seed.font_family,
      font_style: seed.font_style,
      font_postscript: seed.font_postscript,
      text_style_guid: seed.text_style_guid,
      component_key: seed.component_key,
      origin_component_key: seed.origin_component_key,
      fill_style_guid: seed.fill_style_guid,
      stroke_style_guid: seed.stroke_style_guid,
      effect_style_guid: seed.effect_style_guid,
      grid_style_guid: seed.grid_style_guid,
      fill_count: seed.fill_count,
      stroke_count: seed.stroke_count
    }
  end

  defp focused_node_changes(node_changes, nil), do: node_changes
  defp focused_node_changes(node_changes, []), do: node_changes

  defp focused_node_changes(node_changes, focus) do
    node_by_guid = Map.new(node_changes, &{guid(get(&1, :guid)), &1})
    children = node_change_children(node_changes)

    focused_guids =
      focus
      |> Enum.reduce(MapSet.new(), &collect_node_subtree(&2, &1, node_by_guid, children))
      |> collect_node_components(node_by_guid, children)

    Enum.filter(node_changes, &MapSet.member?(focused_guids, guid(get(&1, :guid))))
  end

  defp node_change_children(node_changes) do
    Enum.reduce(node_changes, %{}, fn node_change, children ->
      parent_index = get(node_change, :parent_index)

      parent_guid = parent_index && guid(get(parent_index, :guid))
      node_guid = guid(get(node_change, :guid))

      if parent_guid do
        Map.update(children, parent_guid, [node_guid], &[node_guid | &1])
      else
        children
      end
    end)
  end

  defp collect_node_components(guids, node_by_guid, children) do
    next =
      Enum.reduce(guids, guids, fn guid, acc ->
        node_change = Map.get(node_by_guid, guid)
        symbol_data = node_change && get(node_change, :symbol_data)
        component_guid = symbol_data && guid(get(symbol_data, :symbol_id))

        if is_tuple(component_guid) do
          collect_node_subtree(acc, component_guid, node_by_guid, children)
        else
          acc
        end
      end)

    if MapSet.size(next) == MapSet.size(guids) do
      next
    else
      collect_node_components(next, node_by_guid, children)
    end
  end

  defp collect_node_subtree(guids, guid, node_by_guid, children) do
    if Map.has_key?(node_by_guid, guid) do
      children
      |> Map.get(guid, [])
      |> Enum.reduce(
        MapSet.put(guids, guid),
        &collect_node_subtree(&2, &1, node_by_guid, children)
      )
    else
      guids
    end
  end

  defp public_node_from_change(node_change) do
    parent_index = get(node_change, :parent_index)
    text_data = get(node_change, :text_data)
    font_name = get(node_change, :font_name)

    %Node{
      guid: GUID.format(guid(get(node_change, :guid))),
      node_type: node_change |> get(:type) |> to_string() |> Macro.underscore(),
      name: get(node_change, :name),
      parent_guid: GUID.format(guid(parent_index && get(parent_index, :guid))),
      position: parent_index && get(parent_index, :position),
      size: vector(get(node_change, :size)),
      transform: matrix(get(node_change, :transform)),
      visible: get(node_change, :visible),
      locked: get(node_change, :locked),
      text: text_data && get(text_data, :characters),
      font_family: font_name && get(font_name, :family),
      font_style: font_name && get(font_name, :style),
      font_postscript: font_name && get(font_name, :postscript),
      text_style_guid: style_guid(get(node_change, :style_id_for_text)),
      component_key: get(node_change, :component_key),
      origin_component_key: get(node_change, :origin_component_key),
      fill_style_guid: style_guid(get(node_change, :style_id_for_fill)),
      stroke_style_guid: style_guid(get(node_change, :style_id_for_stroke_fill)),
      effect_style_guid: style_guid(get(node_change, :style_id_for_effect)),
      grid_style_guid: style_guid(get(node_change, :style_id_for_grid)),
      fill_count: count(get(node_change, :fill_paints)),
      stroke_count: count(get(node_change, :stroke_paints))
    }
  end

  defp symbol_overrides(nil), do: []
  defp symbol_overrides(%{symbol_overrides: nil}), do: []

  defp symbol_overrides(%{symbol_overrides: overrides}) do
    Enum.map(overrides, fn override ->
      %SymbolOverride{
        guid_path: guid_path(get(override, :guid_path)),
        overridden_symbol_id: guid(get(override, :overridden_symbol_id)),
        fields: override_fields(override),
        component_prop_assignments:
          component_prop_assignments(get(override, :component_prop_assignments)),
        variable_consumption: multiplayer_entries(get(override, :variable_consumption_map))
      }
    end)
  end

  defp override_fields(override) do
    %{}
    |> put_present(:name, get(override, :name))
    |> put_present(:visible, get(override, :visible))
    |> put_present(
      :text,
      get(override, :text_data) && get(get(override, :text_data), :characters)
    )
    |> put_present(:size, vector(get(override, :size)))
    |> put_present(:transform, matrix(get(override, :transform)))
  end

  defp component_prop_defs(nil), do: []

  defp component_prop_defs(defs) do
    Enum.map(defs, fn defn ->
      %ComponentPropDef{
        id: guid(get(defn, :id)),
        name: get(defn, :name),
        type: get(defn, :type),
        initial_value: component_prop_value(get(defn, :initial_value))
      }
    end)
  end

  defp component_prop_refs(nil), do: []

  defp component_prop_refs(refs) do
    Enum.map(refs, fn ref ->
      %ComponentPropRef{
        def_id: guid(get(ref, :def_id)),
        field: get(ref, :component_prop_node_field) || get(ref, :node_field)
      }
    end)
  end

  defp component_prop_assignments(nil), do: []

  defp component_prop_assignments(assignments) do
    Enum.map(assignments, fn assignment ->
      %ComponentPropAssignment{
        def_id: guid(get(assignment, :def_id)),
        value: component_prop_value(get(assignment, :value)),
        variable_value: variable_data(get(assignment, :var_value))
      }
    end)
  end

  defp derived_symbol_data(nil), do: []

  defp derived_symbol_data(values) do
    Enum.map(values, fn value ->
      %DerivedSymbolData{
        guid_path: guid_path(get(value, :guid_path)),
        size: vector(get(value, :size)),
        transform: matrix(get(value, :transform)),
        font_size: get(value, :font_size),
        line_height: get(value, :line_height),
        letter_spacing: get(value, :letter_spacing),
        stroke_weight: get(value, :stroke_weight),
        derived_text_data: get(value, :derived_text_data),
        fill_geometry: get(value, :fill_geometry) || [],
        stroke_geometry: get(value, :stroke_geometry) || []
      }
    end)
  end

  defp component_prop_value(nil), do: nil

  defp component_prop_value(value) do
    cond do
      is_boolean(get(value, :bool_value)) -> {:bool, get(value, :bool_value)}
      get(value, :text_value) -> {:text, get(get(value, :text_value), :characters)}
      get(value, :guid_value) -> {:guid, guid(get(value, :guid_value))}
      is_number(get(value, :float_value)) -> {:float, get(value, :float_value)}
      get(value, :vector_value) -> {:vector, vector(get(value, :vector_value))}
      true -> value
    end
  end

  defp variable_data(nil), do: nil
  defp variable_data(data), do: data

  defp multiplayer_entries(nil), do: []
  defp multiplayer_entries(%{entries: entries}) when is_list(entries), do: entries
  defp multiplayer_entries(_value), do: []

  defp put_present(map, _key, nil), do: map
  defp put_present(map, key, value), do: Map.put(map, key, value)

  defp guid(nil), do: nil

  defp guid(%{session_id: session_id, local_id: local_id}), do: {session_id, local_id}

  defp guid_path(nil), do: []
  defp guid_path(%{guids: guids}) when is_list(guids), do: Enum.map(guids, &guid/1)

  defp vector(nil), do: nil
  defp vector(%{x: x, y: y}), do: %{x: x, y: y}

  defp matrix(nil), do: nil

  defp matrix(%{m00: m00, m01: m01, m02: m02, m10: m10, m11: m11, m12: m12}) do
    %{m00: m00, m01: m01, m02: m02, m10: m10, m11: m11, m12: m12}
  end

  defp style_guid(nil), do: nil
  defp style_guid(%{guid: guid}), do: guid |> guid() |> GUID.format()
  defp style_guid(_style_id), do: nil

  defp count(nil), do: nil
  defp count(values) when is_list(values), do: length(values)

  defp get(nil, _key), do: nil
  defp get(map, key) when is_map(map), do: Map.get(map, key)
end
