defmodule Figler.Scene.Query do
  @moduledoc """
  Shared query/filter helpers for projected scene nodes.

  The public `Figler.Scene` module exposes the user-facing API. This module
  centralizes list filtering, field filtering, map-to-node conversion, and
  common find predicates so binary/index/graph implementations stay aligned.
  """

  alias Figler.Scene.Graph
  alias Figler.Scene.Graph.GUID
  alias Figler.Scene.Node

  @type scene_node :: Node.t()

  @doc """
  Converts native scene maps into public scene node structs.
  """
  @spec nodes_from_maps([map()]) :: [Node.t()]
  def nodes_from_maps(nodes), do: Enum.map(nodes, &Node.from_map/1)

  @spec maybe_node_from_map(map() | nil) :: Node.t() | nil
  def maybe_node_from_map(nil), do: nil
  def maybe_node_from_map(map), do: Node.from_map(map)

  @spec nodes_by_guids(Graph.t(), [term()]) :: [Node.t()]
  def nodes_by_guids(%Graph{} = graph, guids) do
    graph
    |> Graph.nodes_at(guids)
    |> Enum.map(&public_node/1)
  end

  @doc "Converts an internal graph node to the public scene-node shape."
  @spec public_node(Node.t() | nil) :: Node.t() | nil
  def public_node(nil), do: nil

  def public_node(%Node{} = node) do
    %Node{node | guid: public_guid(node.guid), parent_guid: public_guid(node.parent_guid)}
  end

  @spec apply_field_filter([Node.t()], keyword()) :: [Node.t()]
  def apply_field_filter(nodes, opts) do
    case query_fields(opts) do
      :all -> nodes
      fields -> Enum.map(nodes, &filter_node_fields(&1, fields))
    end
  end

  @spec query_fields(keyword()) :: :all | [String.t()]
  def query_fields(opts) do
    case Keyword.get(opts, :fields, :all) do
      :all -> :all
      fields when is_list(fields) -> fields |> Enum.map(&field_name/1) |> Enum.uniq()
    end
  end

  @spec by_type([Node.t()], atom() | String.t()) :: [Node.t()]
  def by_type(nodes, type) when is_list(nodes) and (is_atom(type) or is_binary(type)) do
    node_type = type |> to_string() |> Macro.underscore()
    Enum.filter(nodes, &(&1.node_type == node_type))
  end

  @spec named([Node.t()], String.t()) :: [Node.t()]
  def named(nodes, name) when is_list(nodes) and is_binary(name) do
    Enum.filter(nodes, &(&1.name == name))
  end

  @spec name_contains([Node.t()], String.t()) :: [Node.t()]
  def name_contains(nodes, needle) when is_list(nodes) and is_binary(needle) do
    Enum.filter(nodes, &(is_binary(&1.name) and String.contains?(&1.name, needle)))
  end

  @spec text_contains([Node.t()], String.t()) :: [Node.t()]
  def text_contains(nodes, needle) when is_list(nodes) and is_binary(needle) do
    Enum.filter(nodes, &(is_binary(&1.text) and String.contains?(&1.text, needle)))
  end

  @spec components([Node.t()]) :: [Node.t()]
  def components(nodes) when is_list(nodes), do: Enum.filter(nodes, &present?(&1.component_key))

  @spec with_fills([Node.t()]) :: [Node.t()]
  def with_fills(nodes) when is_list(nodes), do: Enum.filter(nodes, &positive?(&1.fill_count))

  @spec with_strokes([Node.t()]) :: [Node.t()]
  def with_strokes(nodes) when is_list(nodes), do: Enum.filter(nodes, &positive?(&1.stroke_count))

  @doc """
  Returns projected field values from nodes, similar to `Floki.attribute/2`.
  """
  @spec attribute([Node.t()], atom() | String.t()) :: [term()]
  def attribute(nodes, field) when is_list(nodes) and (is_atom(field) or is_binary(field)) do
    field = node_field(field)

    nodes
    |> Enum.map(&Map.get(&1, field))
    |> Enum.reject(&is_nil/1)
  end

  @doc """
  Returns projected text from nodes, similar to `Floki.text/2`.
  """
  @spec text([Node.t()], keyword()) :: String.t()
  def text(nodes, opts \\ []) when is_list(nodes) and is_list(opts) do
    nodes
    |> attribute(:text)
    |> Enum.join(Keyword.get(opts, :sep, ""))
  end

  @spec filter_find_results([Node.t()], keyword()) :: [Node.t()]
  def filter_find_results(nodes, opts) do
    Enum.filter(nodes, fn node ->
      Enum.all?(opts, fn
        {:type, type} -> node.node_type == type |> to_string() |> Macro.underscore()
        {:name, name} -> node.name == name
        {:name_contains, needle} -> is_binary(node.name) and String.contains?(node.name, needle)
        {:text_contains, needle} -> is_binary(node.text) and String.contains?(node.text, needle)
        {_key, _value} -> true
      end)
    end)
  end

  @spec node_field(atom() | String.t()) :: atom()
  def node_field(:type), do: :node_type
  def node_field("type"), do: :node_type
  def node_field(field) when is_atom(field), do: field

  def node_field(field) when is_binary(field) do
    String.to_existing_atom(field)
  rescue
    ArgumentError -> :__unknown_field__
  end

  defp public_guid(nil), do: nil
  defp public_guid(guid) when is_tuple(guid), do: GUID.format(guid)
  defp public_guid(guid), do: guid

  defp filter_node_fields(%Node{} = node, fields) do
    fields = Enum.uniq(["guid", "node_type" | fields])

    node
    |> Map.from_struct()
    |> Map.take(Enum.map(fields, &node_field/1))
    |> Node.from_map()
  end

  defp field_name(field) when is_atom(field), do: Atom.to_string(field)
  defp field_name(field) when is_binary(field), do: field

  defp present?(value), do: is_binary(value) and value != ""
  defp positive?(value), do: is_integer(value) and value > 0
end
