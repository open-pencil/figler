defmodule FigKiwi.Scene.Node do
  @moduledoc """
  Lightweight projected scene node.

  This is a flattened projection of `FigKiwi.Schema.NodeChange`, backed by the
  generated Kiwi schema metadata at compile time. It is intentionally smaller
  than `NodeChange` so large scenes can be indexed without materializing every
  schema field.
  """

  alias FigKiwi.Scene.Projection

  @source_module Projection.source_module()
  @source_fields Projection.source_fields()
  @parent_index_source_fields Projection.parent_index_source_fields()
  @field_names Projection.field_names()

  @enforce_keys [:guid, :node_type]
  defstruct @field_names ++ [children: nil]

  @type t :: %__MODULE__{
          guid: String.t(),
          node_type: FigKiwi.Schema.NodeType.t() | String.t(),
          name: String.t() | nil,
          parent_guid: String.t() | nil,
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
          children: [t()] | nil
        }

  @doc """
  Returns the generated Kiwi schema module this projection is derived from.
  """
  @spec source_module() :: module()
  def source_module, do: @source_module

  @doc """
  Returns the `NodeChange` fields consumed by this projection.
  """
  @spec source_fields() :: [atom()]
  def source_fields, do: @source_fields

  @doc """
  Returns projected scene node field names.
  """
  @spec field_names() :: [atom()]
  def field_names, do: @field_names

  @doc """
  Returns the `ParentIndex` fields flattened into this projection.
  """
  @spec parent_index_source_fields() :: [atom()]
  def parent_index_source_fields, do: @parent_index_source_fields

  @doc false
  @spec from_map(map()) :: t()
  def from_map(map) when is_map(map) do
    struct!(__MODULE__, Map.take(map, @field_names))
  end
end
