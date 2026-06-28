defmodule Figler.Test.GraphBuilder do
  @moduledoc """
  Test helpers for constructing scene graph resolver inputs.

  The helpers keep graph resolver tests concise by building seed nodes,
  overrides, component-property values, and resolved graphs with the same
  structs used by production code.
  """

  alias Figler.Scene.Graph.Build
  alias Figler.Scene.Graph.Component.PropertyAssignment
  alias Figler.Scene.Graph.Component.PropertyRef
  alias Figler.Scene.Graph.Seed.Node, as: SeedNode
  alias Figler.Scene.Graph.Symbol.DerivedData, as: DerivedSymbolData
  alias Figler.Scene.Graph.Symbol.Override, as: SymbolOverride

  def node(guid, type, attrs \\ []) do
    struct!(SeedNode, Keyword.merge([guid: guid, node_type: Atom.to_string(type)], attrs))
  end

  def component(guid, attrs \\ []), do: node(guid, :component, attrs)

  def text(guid, parent_guid, text, attrs \\ []),
    do: node(guid, :text, Keyword.merge([parent_guid: parent_guid, text: text], attrs))

  def instance(guid, symbol_id, attrs \\ []) do
    node(guid, :instance, Keyword.merge([symbol_id: symbol_id], attrs))
  end

  def symbol_override(guid_path, fields),
    do: %SymbolOverride{guid_path: guid_path, fields: fields}

  def symbol_swap(guid_path, component_guid, attrs \\ []) do
    struct!(
      SymbolOverride,
      Keyword.merge([guid_path: guid_path, overridden_symbol_id: component_guid], attrs)
    )
  end

  def prop_ref(def_id, field), do: %PropertyRef{def_id: def_id, field: field}
  def prop_assignment(def_id, value), do: %PropertyAssignment{def_id: def_id, value: value}

  def derived_symbol_data(guid_path, attrs \\ []) do
    struct!(DerivedSymbolData, Keyword.put(attrs, :guid_path, guid_path))
  end

  def variable_ref(field, value) do
    struct(Figler.Schema.VariableDataMapEntry,
      variable_field: field,
      variable_data:
        struct(Figler.Schema.VariableData,
          data_type: :float,
          resolved_data_type: :float,
          value: struct(Figler.Schema.VariableAnyValue, float_value: value)
        )
    )
  end

  def resolve(seed_nodes, opts \\ []) do
    stages = Keyword.get(opts, :stages, [:populate_instances, :symbol_overrides])
    opts = Keyword.put_new(opts, :resource, make_ref())

    seed_nodes
    |> Build.from_seed(Keyword.put(opts, :stages, stages))
    |> Build.resolve()
  end
end
