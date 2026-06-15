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
          guid: String.t(),
          node_type: String.t(),
          name: String.t() | nil,
          parent_guid: String.t() | nil,
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
          component_guid: String.t() | nil,
          symbol_id: String.t() | nil,
          override_key: String.t() | nil,
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
  Builds a seed node from the current projected scene node.
  """
  @spec from_node(Node.t()) :: t()
  def from_node(%Node{} = node) do
    %__MODULE__{
      guid: node.guid,
      node_type: node.node_type,
      name: node.name,
      parent_guid: node.parent_guid,
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
      guid: seed.guid,
      node_type: seed.node_type,
      name: seed.name,
      parent_guid: seed.parent_guid,
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
end
