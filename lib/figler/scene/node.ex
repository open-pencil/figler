defmodule Figler.Scene.Node do
  @moduledoc """
  Lightweight projected scene node.

  This is a flattened projection of `Figler.Schema.NodeChange`, backed by the
  generated Kiwi schema metadata at compile time. It is intentionally smaller
  than `NodeChange` so large scenes can be indexed without materializing every
  schema field.
  """

  alias Figler.Scene.Projection

  @source_module Projection.source_module()
  @source_fields Projection.source_fields()
  @parent_index_source_fields Projection.parent_index_source_fields()
  @field_names Projection.field_names()

  @enforce_keys [:guid, :node_type]
  defstruct @field_names ++ [children: nil]

  @type t :: %__MODULE__{}

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
