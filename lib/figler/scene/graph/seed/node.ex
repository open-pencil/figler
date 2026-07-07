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
  alias Figler.Scene.Graph.Seed.Projection, as: SeedProjection
  alias Figler.Scene.Graph.Seed.Value
  alias Figler.Scene.Node
  alias Figler.Scene.Projection

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
  Builds a seed node from a generated `NodeChange` struct, including initial
  graph resolver metadata.
  """
  @spec from_node_change(Figler.Schema.NodeChange.t() | map()) :: t()
  def from_node_change(node_change) when is_map(node_change) do
    symbol_data = get(node_change, :symbol_data)
    symbol_id = Value.guid(symbol_data && get(symbol_data, :symbol_id))
    projected = projected_values(node_change)

    projected
    |> Map.update!(:guid, &GUID.parse!/1)
    |> Map.update!(:parent_guid, &GUID.parse/1)
    |> Map.put(:symbol_id, symbol_id)
    |> Map.put(:component_guid, symbol_id)
    |> then(&struct!(__MODULE__, &1))
    |> put_resolver_metadata(node_change)
  end

  defp put_resolver_metadata(%__MODULE__{} = seed, node_change) do
    struct!(seed, SeedProjection.metadata(node_change))
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
    seed
    |> Map.from_struct()
    |> Map.take(@projected_fields)
    |> Map.update!(:locked, &(&1 || false))
    |> Map.update!(:text, &(&1 || ""))
    |> then(&struct!(Node, &1))
  end

  @doc """
  Converts a seed node back to the public projected node struct.
  """
  @spec to_node(t()) :: Node.t()
  def to_node(%__MODULE__{} = seed) do
    seed
    |> to_graph_node()
    |> Map.update!(:guid, &GUID.format/1)
    |> Map.update!(:parent_guid, &GUID.format/1)
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

  defp projected_values(node_change) do
    Map.new(Projection.fields(), fn %{name: name} = field ->
      {name, projected_value(field, node_change)}
    end)
  end

  defp projected_value(%{name: :guid}, node_change),
    do: GUID.format(Value.guid(get(node_change, :guid)))

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

  defp parent_index_value(:guid, parent_index),
    do: GUID.format(Value.guid(get(parent_index, :guid)))

  defp parent_index_value(field, parent_index), do: parent_index && get(parent_index, field)

  defp projected_node_change_value(value, %{value: :vector}), do: Value.vector(value)
  defp projected_node_change_value(value, %{value: :matrix}), do: Value.matrix(value)
  defp projected_node_change_value(value, %{value: :count}), do: count(value)
  defp projected_node_change_value(value, _projection), do: value

  defp style_guid(nil), do: nil
  defp style_guid(%{guid: guid}), do: guid |> Value.guid() |> GUID.format()
  defp style_guid(_style_id), do: nil

  defp count(nil), do: nil
  defp count(values) when is_list(values), do: length(values)

  defp get(nil, _key), do: nil
  defp get(map, key) when is_map(map), do: Map.get(map, key)
end
