defmodule FigKiwi.Test.GraphBuilder do
  @moduledoc false

  alias FigKiwi.Scene.Graph.ComponentPropAssignment
  alias FigKiwi.Scene.Graph.ComponentPropRef
  alias FigKiwi.Scene.Graph.DerivedSymbolData
  alias FigKiwi.Scene.Graph.Resolver
  alias FigKiwi.Scene.Graph.SeedNode
  alias FigKiwi.Scene.Graph.SymbolOverride

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

  def prop_ref(def_id, field), do: %ComponentPropRef{def_id: def_id, field: field}
  def prop_assignment(def_id, value), do: %ComponentPropAssignment{def_id: def_id, value: value}

  def derived_symbol_data(guid_path, attrs \\ []) do
    struct!(DerivedSymbolData, Keyword.put(attrs, :guid_path, guid_path))
  end

  def variable_ref(field, value) do
    struct(FigKiwi.Schema.VariableDataMapEntry,
      variable_field: field,
      variable_data:
        struct(FigKiwi.Schema.VariableData,
          data_type: :float,
          resolved_data_type: :float,
          value: struct(FigKiwi.Schema.VariableAnyValue, float_value: value)
        )
    )
  end

  def resolve(seed_nodes, opts \\ []) do
    stages = Keyword.get(opts, :stages, [:populate_instances, :symbol_overrides])
    opts = Keyword.put_new(opts, :resource, make_ref())

    seed_nodes
    |> Resolver.from_seed(Keyword.put(opts, :stages, stages))
    |> Resolver.resolve()
  end
end
