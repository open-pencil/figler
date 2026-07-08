# credo:disable-for-this-file Credo.Check.Warning.StructFieldAmount

defmodule Figler.Scene.Graph.Seed.Node do
  @moduledoc """
  Raw projected node plus graph-resolver metadata.

  A seed node is the input to `Figler.Scene.Graph` resolution. It is not the
  final effective node: resolver stages may clone it, patch fields, or attach
  provenance. Override-related fields are intentionally structured even when
  currently empty so the Elixir resolver can grow without changing public shape.
  """

  alias Figler.Scene.Graph.GUID
  alias Figler.Scene.Graph.Seed.Extraction.ComponentProps
  alias Figler.Scene.Graph.Seed.Extraction.DerivedData
  alias Figler.Scene.Graph.Seed.Extraction.SymbolOverrides
  alias Figler.Scene.Graph.Seed.Projection, as: SeedProjection
  alias Figler.Scene.Graph.Seed.Value
  alias Figler.Scene.Node

  @projected_fields Node.field_names()

  @enforce_keys [:guid, :node_type]
  defstruct @projected_fields ++ SeedProjection.struct_fields()

  @type t :: %__MODULE__{}

  @doc """
  Builds seed nodes from a decoded generated `Message` struct.
  """
  @spec from_message(Figler.Schema.Message.t() | map(), keyword()) :: [t()]
  def from_message(message, opts \\ [])

  def from_message(%{node_changes: node_changes}, opts) when is_list(node_changes) do
    node_changes
    |> focused_node_changes(Keyword.get(opts, :focus))
    |> Enum.map(&from_node_change/1)
  end

  @doc """
  Builds seed nodes from native graph seed records.
  """
  @spec from_native_records([list()]) :: [t()]
  def from_native_records(records) when is_list(records) do
    Enum.map(records, &from_native_record/1)
  end

  @doc """
  Builds a seed node from a generated `NodeChange` struct, including initial
  graph resolver metadata.
  """
  @spec from_node_change(Figler.Schema.NodeChange.t() | map()) :: t()
  def from_node_change(node_change) when is_map(node_change) do
    parent_index = get(node_change, :parent_index)
    text_data = get(node_change, :text_data)
    font_name = get(node_change, :font_name)
    symbol_data = get(node_change, :symbol_data)
    symbol_id = Value.guid(symbol_data && get(symbol_data, :symbol_id))

    %__MODULE__{
      guid: Value.guid(get(node_change, :guid)),
      node_type: node_type(get(node_change, :type)),
      name: get(node_change, :name),
      parent_guid: parent_index && Value.guid(get(parent_index, :guid)),
      position: parent_index && get(parent_index, :position),
      size: Value.vector(get(node_change, :size)),
      transform: Value.matrix(get(node_change, :transform)),
      visible: get(node_change, :visible),
      locked: get(node_change, :locked),
      opacity: get(node_change, :opacity),
      text: text_data && get(text_data, :characters),
      font_family: font_name && get(font_name, :family),
      font_style: font_name && get(font_name, :style),
      font_postscript: font_name && get(font_name, :postscript),
      font_size: get(node_change, :font_size),
      text_style_guid: style_guid(get(node_change, :style_id_for_text)),
      component_key: get(node_change, :component_key),
      origin_component_key: get(node_change, :origin_component_key),
      fill_style_guid: style_guid(get(node_change, :style_id_for_fill)),
      stroke_style_guid: style_guid(get(node_change, :style_id_for_stroke_fill)),
      effect_style_guid: style_guid(get(node_change, :style_id_for_effect)),
      grid_style_guid: style_guid(get(node_change, :style_id_for_grid)),
      fill_count: count(get(node_change, :fill_paints)),
      stroke_count: count(get(node_change, :stroke_paints)),
      override_key: Value.guid(get(node_change, :override_key)),
      stack_mode: get(node_change, :stack_mode),
      stack_spacing: get(node_change, :stack_spacing),
      stack_horizontal_padding: get(node_change, :stack_horizontal_padding),
      stack_vertical_padding: get(node_change, :stack_vertical_padding),
      stack_padding_right: get(node_change, :stack_padding_right),
      stack_padding_bottom: get(node_change, :stack_padding_bottom),
      symbol_overrides: SymbolOverrides.all(symbol_data),
      component_prop_defs: ComponentProps.defs(get(node_change, :component_prop_defs)),
      component_prop_refs: ComponentProps.refs(get(node_change, :component_prop_refs)),
      component_prop_assignments:
        ComponentProps.assignments(get(node_change, :component_prop_assignments)),
      derived_symbol_data: DerivedData.all(get(node_change, :derived_symbol_data)),
      variable_consumption: multiplayer_entries(get(node_change, :variable_consumption_map)),
      variable_data_values: multiplayer_entries(get(node_change, :variable_data_values)),
      symbol_id: symbol_id,
      component_guid: symbol_id
    }
  end

  defp from_native_record([
         guid,
         node_type,
         name,
         parent_guid,
         position,
         size,
         transform,
         visible,
         locked,
         opacity,
         text,
         font_family,
         _font_style,
         _font_postscript,
         font_size,
         text_style_guid,
         component_key,
         origin_component_key,
         fill_style_guid,
         stroke_style_guid,
         effect_style_guid,
         grid_style_guid,
         fill_count,
         stroke_count,
         override_key,
         stack_mode,
         stack_spacing,
         stack_horizontal_padding,
         stack_vertical_padding,
         stack_padding_right,
         stack_padding_bottom,
         symbol_data,
         component_prop_defs,
         component_prop_refs,
         component_prop_assignments,
         derived_symbol_data,
         variable_consumption,
         variable_data_values
       ]) do
    symbol_id = Value.guid(get(symbol_data, :symbol_id))
    text_data = text
    font_name = font_family

    %__MODULE__{
      guid: guid,
      node_type: node_type,
      name: name,
      parent_guid: parent_guid,
      position: position,
      size: Value.vector(size),
      transform: Value.matrix(transform),
      visible: visible,
      locked: locked,
      opacity: opacity,
      text: get(text_data, :characters),
      font_family: get(font_name, :family),
      font_style: get(font_name, :style),
      font_postscript: get(font_name, :postscript),
      font_size: font_size,
      text_style_guid: style_guid(text_style_guid),
      component_key: component_key,
      origin_component_key: origin_component_key,
      fill_style_guid: style_guid(fill_style_guid),
      stroke_style_guid: style_guid(stroke_style_guid),
      effect_style_guid: style_guid(effect_style_guid),
      grid_style_guid: style_guid(grid_style_guid),
      fill_count: fill_count,
      stroke_count: stroke_count,
      override_key: override_key,
      stack_mode: stack_mode,
      stack_spacing: stack_spacing,
      stack_horizontal_padding: stack_horizontal_padding,
      stack_vertical_padding: stack_vertical_padding,
      stack_padding_right: stack_padding_right,
      stack_padding_bottom: stack_padding_bottom,
      symbol_overrides: SymbolOverrides.all(symbol_data),
      component_prop_defs: ComponentProps.defs(component_prop_defs),
      component_prop_refs: ComponentProps.refs(component_prop_refs),
      component_prop_assignments: ComponentProps.assignments(component_prop_assignments),
      derived_symbol_data: DerivedData.all(derived_symbol_data),
      variable_consumption: multiplayer_entries(variable_consumption),
      variable_data_values: multiplayer_entries(variable_data_values),
      symbol_id: symbol_id,
      component_guid: symbol_id
    }
  end

  @doc """
  Builds a seed node from the current projected scene node.
  """
  @spec from_node(Node.t()) :: t()
  def from_node(%Node{} = node) do
    node
    |> Map.from_struct()
    |> Map.take(@projected_fields)
    |> Map.update!(:guid, &GUID.parse!/1)
    |> Map.update!(:parent_guid, &GUID.parse/1)
    |> then(&struct!(__MODULE__, &1))
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
  Builds a cloned seed only when later resolver stages need seed metadata.
  """
  @spec graph_clone(t() | nil, GUID.graph_guid(), GUID.graph_guid()) :: t() | nil
  def graph_clone(nil, _clone_guid, _parent_guid), do: nil

  def graph_clone(%__MODULE__{} = seed, clone_guid, parent_guid) do
    if graph_clone_seed?(seed), do: clone(seed, clone_guid, parent_guid)
  end

  @doc """
  Returns true when a cloned seed carries metadata used after clone population.
  """
  @spec graph_clone_seed?(t()) :: boolean()
  def graph_clone_seed?(%__MODULE__{} = seed) do
    seed.node_type == "instance" or
      stack_metadata?(seed) or
      non_empty?(seed.component_prop_assignments) or
      non_empty?(seed.derived_symbol_data) or
      non_empty?(seed.variable_consumption) or
      non_empty?(seed.variable_data_values) or
      style_metadata?(seed)
  end

  @doc """
  Converts a seed node to an internal graph node with parsed GUIDs.
  """
  @spec to_graph_node(t()) :: Node.t()
  def to_graph_node(%__MODULE__{} = seed) do
    %Node{
      guid: seed.guid,
      node_type: seed.node_type,
      name: seed.name,
      parent_guid: seed.parent_guid,
      position: seed.position,
      size: seed.size,
      transform: seed.transform,
      visible: seed.visible,
      locked: seed.locked || false,
      opacity: seed.opacity,
      text: seed.text || "",
      font_family: seed.font_family,
      font_style: seed.font_style,
      font_postscript: seed.font_postscript,
      font_size: seed.font_size,
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

  @doc """
  Converts a seed node back to the public projected node struct.
  """
  @spec to_node(t()) :: Node.t()
  def to_node(%__MODULE__{} = seed) do
    %Node{
      to_graph_node(seed)
      | guid: GUID.format(seed.guid),
        parent_guid: GUID.format(seed.parent_guid)
    }
  end

  defp stack_metadata?(%__MODULE__{} = seed) do
    not is_nil(seed.stack_mode) or
      not is_nil(seed.stack_spacing) or
      not is_nil(seed.stack_horizontal_padding) or
      not is_nil(seed.stack_vertical_padding) or
      not is_nil(seed.stack_padding_right) or
      not is_nil(seed.stack_padding_bottom)
  end

  defp style_metadata?(%__MODULE__{} = seed) do
    not is_nil(seed.text_style_guid) or
      not is_nil(seed.fill_style_guid) or
      not is_nil(seed.stroke_style_guid) or
      not is_nil(seed.effect_style_guid) or
      not is_nil(seed.grid_style_guid)
  end

  defp non_empty?(value), do: value not in [nil, []]

  defp focused_node_changes(node_changes, nil), do: node_changes
  defp focused_node_changes(node_changes, []), do: node_changes

  defp focused_node_changes(node_changes, focus) do
    node_by_guid = Map.new(node_changes, &{Value.guid(get(&1, :guid)), &1})
    children = node_change_children(node_changes)

    focused_guids =
      focus
      |> Enum.reduce(MapSet.new(), &collect_node_subtree(&2, &1, node_by_guid, children))
      |> collect_node_components(node_by_guid, children)

    Enum.filter(node_changes, &MapSet.member?(focused_guids, Value.guid(get(&1, :guid))))
  end

  defp node_change_children(node_changes) do
    Enum.reduce(node_changes, %{}, fn node_change, children ->
      parent_index = get(node_change, :parent_index)

      parent_guid = parent_index && Value.guid(get(parent_index, :guid))
      node_guid = Value.guid(get(node_change, :guid))

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
        component_guid = symbol_data && Value.guid(get(symbol_data, :symbol_id))

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

  defp node_type(type) when is_atom(type), do: Atom.to_string(type)
  defp node_type(type), do: type |> to_string() |> Macro.underscore()

  defp style_guid(nil), do: nil
  defp style_guid(%{guid: guid}), do: guid |> Value.guid() |> GUID.format()
  defp style_guid(_style_id), do: nil

  defp count(nil), do: nil
  defp count(values) when is_list(values), do: length(values)

  defp multiplayer_entries(nil), do: []
  defp multiplayer_entries(%{entries: entries}) when is_list(entries), do: entries
  defp multiplayer_entries(_value), do: []

  defp get(nil, _key), do: nil
  defp get(map, key) when is_map(map), do: Map.get(map, key)
end
