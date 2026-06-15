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
  @spec from_message(FigKiwi.Schema.Message.t()) :: [t()]
  def from_message(%FigKiwi.Schema.Message{node_changes: node_changes})
      when is_list(node_changes) do
    Enum.map(node_changes, &from_node_change/1)
  end

  @doc """
  Builds a seed node from a generated `NodeChange` struct, including initial
  graph resolver metadata.
  """
  @spec from_node_change(FigKiwi.Schema.NodeChange.t()) :: t()
  def from_node_change(%FigKiwi.Schema.NodeChange{} = node_change) do
    node = public_node_from_change(node_change)

    %__MODULE__{
      from_node(node)
      | symbol_id: guid(node_change.symbol_data && node_change.symbol_data.symbol_id),
        override_key: guid(node_change.override_key),
        component_guid: guid(node_change.symbol_data && node_change.symbol_data.symbol_id),
        symbol_overrides: symbol_overrides(node_change.symbol_data),
        component_prop_defs: component_prop_defs(node_change.component_prop_defs),
        component_prop_refs: component_prop_refs(node_change.component_prop_refs),
        component_prop_assignments:
          component_prop_assignments(node_change.component_prop_assignments),
        derived_symbol_data: derived_symbol_data(node_change.derived_symbol_data),
        variable_consumption: multiplayer_entries(node_change.variable_consumption_map),
        variable_data_values: multiplayer_entries(node_change.variable_data_values)
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

  defp public_node_from_change(node_change) do
    %Node{
      guid: GUID.format(guid(node_change.guid)),
      node_type: node_change.type |> to_string() |> Macro.underscore(),
      name: node_change.name,
      parent_guid: GUID.format(guid(node_change.parent_index && node_change.parent_index.guid)),
      position: node_change.parent_index && node_change.parent_index.position,
      size: vector(node_change.size),
      transform: matrix(node_change.transform),
      visible: node_change.visible,
      locked: node_change.locked,
      text: node_change.text_data && node_change.text_data.characters,
      font_family: node_change.font_name && node_change.font_name.family,
      font_style: node_change.font_name && node_change.font_name.style,
      font_postscript: node_change.font_name && node_change.font_name.postscript,
      text_style_guid: style_guid(node_change.style_id_for_text),
      component_key: node_change.component_key,
      origin_component_key: node_change.origin_component_key,
      fill_style_guid: style_guid(node_change.style_id_for_fill),
      stroke_style_guid: style_guid(node_change.style_id_for_stroke_fill),
      effect_style_guid: style_guid(node_change.style_id_for_effect),
      grid_style_guid: style_guid(node_change.style_id_for_grid),
      fill_count: count(node_change.fill_paints),
      stroke_count: count(node_change.stroke_paints)
    }
  end

  defp symbol_overrides(nil), do: []
  defp symbol_overrides(%{symbol_overrides: nil}), do: []

  defp symbol_overrides(%{symbol_overrides: overrides}) do
    Enum.map(overrides, fn override ->
      %SymbolOverride{
        guid_path: guid_path(override.guid_path),
        overridden_symbol_id: guid(override.overridden_symbol_id),
        fields: override_fields(override),
        component_prop_assignments:
          component_prop_assignments(override.component_prop_assignments),
        variable_consumption: multiplayer_entries(override.variable_consumption_map)
      }
    end)
  end

  defp override_fields(override) do
    %{}
    |> put_present(:name, override.name)
    |> put_present(:visible, override.visible)
    |> put_present(:text, override.text_data && override.text_data.characters)
    |> put_present(:size, vector(override.size))
    |> put_present(:transform, matrix(override.transform))
  end

  defp component_prop_defs(nil), do: []

  defp component_prop_defs(defs) do
    Enum.map(defs, fn defn ->
      %ComponentPropDef{
        id: guid(defn.id),
        name: defn.name,
        type: defn.type,
        initial_value: component_prop_value(defn.initial_value)
      }
    end)
  end

  defp component_prop_refs(nil), do: []

  defp component_prop_refs(refs) do
    Enum.map(refs, fn ref ->
      %ComponentPropRef{
        def_id: guid(ref.def_id),
        field: ref.component_prop_node_field || ref.node_field
      }
    end)
  end

  defp component_prop_assignments(nil), do: []

  defp component_prop_assignments(assignments) do
    Enum.map(assignments, fn assignment ->
      %ComponentPropAssignment{
        def_id: guid(assignment.def_id),
        value: component_prop_value(assignment.value),
        variable_value: variable_data(assignment.var_value)
      }
    end)
  end

  defp derived_symbol_data(nil), do: []

  defp derived_symbol_data(values) do
    Enum.map(values, fn value ->
      %DerivedSymbolData{
        guid_path: guid_path(value.guid_path),
        size: vector(value.size),
        transform: matrix(value.transform),
        font_size: value.font_size,
        line_height: value.line_height,
        letter_spacing: value.letter_spacing,
        stroke_weight: value.stroke_weight,
        derived_text_data: value.derived_text_data,
        fill_geometry: value.fill_geometry || [],
        stroke_geometry: value.stroke_geometry || []
      }
    end)
  end

  defp component_prop_value(nil), do: nil

  defp component_prop_value(value) do
    cond do
      is_boolean(value.bool_value) -> {:bool, value.bool_value}
      value.text_value -> {:text, value.text_value.characters}
      value.guid_value -> {:guid, guid(value.guid_value)}
      is_number(value.float_value) -> {:float, value.float_value}
      value.vector_value -> {:vector, vector(value.vector_value)}
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

  defp guid(%FigKiwi.Schema.GUID{} = guid), do: GUID.from_schema(guid)

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

  defp count(nil), do: nil
  defp count(values) when is_list(values), do: length(values)
end
