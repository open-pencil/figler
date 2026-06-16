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
  alias FigKiwi.Scene.Graph.SeedProjection
  alias FigKiwi.Scene.Graph.SymbolOverride
  alias FigKiwi.Scene.Node
  alias FigKiwi.Scene.Projection

  @projected_fields Node.field_names()
  @resolver_metadata_fields SeedProjection.resolver_metadata_fields()

  @enforce_keys [:guid, :node_type]
  defstruct @projected_fields ++ SeedProjection.struct_fields()

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
          opacity: number() | nil,
          text: String.t() | nil,
          font_family: String.t() | nil,
          font_style: String.t() | nil,
          font_postscript: String.t() | nil,
          font_size: number() | nil,
          text_style_guid: String.t() | nil,
          component_key: String.t() | nil,
          origin_component_key: String.t() | nil,
          fill_style_guid: String.t() | nil,
          stroke_style_guid: String.t() | nil,
          effect_style_guid: String.t() | nil,
          grid_style_guid: String.t() | nil,
          fill_count: non_neg_integer() | nil,
          stroke_count: non_neg_integer() | nil,
          stack_mode: atom() | String.t() | nil,
          stack_spacing: number() | nil,
          stack_horizontal_padding: number() | nil,
          stack_vertical_padding: number() | nil,
          stack_padding_right: number() | nil,
          stack_padding_bottom: number() | nil,
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
    %__MODULE__{} = seed = from_node(node)

    seed
    |> struct!(%{symbol_id: symbol_id, component_guid: symbol_id})
    |> put_resolver_metadata(node_change)
  end

  defp put_resolver_metadata(%__MODULE__{} = seed, node_change) do
    @resolver_metadata_fields
    |> Map.new(&{&1, resolver_metadata_value(&1, node_change)})
    |> then(&struct!(seed, &1))
  end

  defp resolver_metadata_value(field, node_change) do
    field
    |> SeedProjection.value_kind()
    |> resolver_metadata_value_for(node_change)
  end

  defp resolver_metadata_value_for(:guid, node_change), do: guid(get(node_change, :override_key))

  defp resolver_metadata_value_for(:symbol_overrides, node_change),
    do: node_change |> get(:symbol_data) |> symbol_overrides()

  defp resolver_metadata_value_for(:component_prop_defs, node_change),
    do: node_change |> get(:component_prop_defs) |> component_prop_defs()

  defp resolver_metadata_value_for(:component_prop_refs, node_change),
    do: node_change |> get(:component_prop_refs) |> component_prop_refs()

  defp resolver_metadata_value_for(:component_prop_assignments, node_change),
    do: node_change |> get(:component_prop_assignments) |> component_prop_assignments()

  defp resolver_metadata_value_for(:derived_symbol_data, node_change),
    do: node_change |> get(:derived_symbol_data) |> derived_symbol_data()

  defp resolver_metadata_value_for({:multiplayer_entries, source_field}, node_change),
    do: node_change |> get(source_field) |> multiplayer_entries()

  defp resolver_metadata_value_for({:field, field}, node_change), do: get(node_change, field)

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
    |> Map.put(:source, node)
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
  Converts a seed node back to the public projected node struct.
  """
  @spec to_node(t()) :: Node.t()
  def to_node(%__MODULE__{} = seed) do
    seed
    |> Map.from_struct()
    |> Map.take(@projected_fields)
    |> Map.update!(:guid, &GUID.format/1)
    |> Map.update!(:parent_guid, &GUID.format/1)
    |> Map.update!(:locked, &(&1 || false))
    |> Map.update!(:text, &(&1 || ""))
    |> then(&struct!(Node, &1))
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
    values =
      Projection.fields()
      |> Map.new(fn %{name: name} = field -> {name, projected_value(field, node_change)} end)

    struct!(Node, values)
  end

  defp projected_value(%{name: :guid}, node_change),
    do: GUID.format(guid(get(node_change, :guid)))

  defp projected_value(%{name: :node_type}, node_change),
    do: node_change |> get(:type) |> to_string() |> Macro.underscore()

  defp projected_value(%{source: {:parent_index, field}}, node_change) do
    parent_index = get(node_change, :parent_index)
    parent_index_value(field, parent_index)
  end

  defp projected_value(%{source: {:text_data, field}}, node_change) do
    node_change |> get(:text_data) |> get(field)
  end

  defp projected_value(%{source: {:font_name, field}}, node_change) do
    node_change |> get(:font_name) |> get(field)
  end

  defp projected_value(%{source: {:style_id, :guid}, name: name}, node_change) do
    node_change |> get(Projection.style_id_field(name)) |> style_guid()
  end

  defp projected_value(%{source: {:node_change, :type}}, _node_change), do: nil

  defp projected_value(%{source: {:node_change, field}} = projection, node_change) do
    node_change |> get(field) |> projected_node_change_value(projection)
  end

  defp parent_index_value(:guid, nil), do: nil
  defp parent_index_value(:guid, parent_index), do: GUID.format(guid(get(parent_index, :guid)))
  defp parent_index_value(field, parent_index), do: parent_index && get(parent_index, field)

  defp projected_node_change_value(value, %{value: :vector}), do: vector(value)
  defp projected_node_change_value(value, %{value: :matrix}), do: matrix(value)
  defp projected_node_change_value(value, %{value: :count}), do: count(value)
  defp projected_node_change_value(value, _projection), do: value

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
