defmodule Figler.Scene.Graph.Seed.Extraction.ComponentProps do
  @moduledoc """
  Extracts component property definitions, references, and assignments.

  This module converts generated component property schema values into the
  graph resolver structs used for instance overrides and component property
  synchronization.
  """

  alias Figler.Scene.Graph.Component.PropertyAssignment
  alias Figler.Scene.Graph.Component.PropertyDef
  alias Figler.Scene.Graph.Component.PropertyRef
  alias Figler.Scene.Graph.Seed.Value

  def defs(nil), do: []

  def defs(defs) do
    Enum.map(defs, fn defn ->
      %PropertyDef{
        id: Value.guid(get(defn, :id)),
        name: get(defn, :name),
        type: get(defn, :type),
        initial_value: value(get(defn, :initial_value))
      }
    end)
  end

  def refs(nil), do: []

  def refs(refs) do
    Enum.map(refs, fn ref ->
      %PropertyRef{
        def_id: Value.guid(get(ref, :def_id)),
        field: get(ref, :component_prop_node_field) || get(ref, :node_field)
      }
    end)
  end

  def assignments(nil), do: []

  def assignments(assignments) do
    Enum.map(assignments, fn assignment ->
      %PropertyAssignment{
        def_id: Value.guid(get(assignment, :def_id)),
        value: value(get(assignment, :value)),
        variable_value: variable_data(get(assignment, :var_value))
      }
    end)
  end

  def value(nil), do: nil

  def value(value) do
    cond do
      is_boolean(get(value, :bool_value)) -> {:bool, get(value, :bool_value)}
      get(value, :text_value) -> {:text, get(get(value, :text_value), :characters)}
      get(value, :guid_value) -> {:guid, Value.guid(get(value, :guid_value))}
      is_number(get(value, :float_value)) -> {:float, get(value, :float_value)}
      get(value, :vector_value) -> {:vector, Value.vector(get(value, :vector_value))}
      true -> value
    end
  end

  defp variable_data(nil), do: nil
  defp variable_data(data), do: data

  defp get(nil, _key), do: nil
  defp get(map, key) when is_map(map), do: Map.get(map, key)
end
