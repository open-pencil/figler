defmodule FigKiwi.Scene.Node do
  @moduledoc """
  Lightweight projected scene node.

  This is a flattened projection of `FigKiwi.Schema.NodeChange`, backed by the
  generated Kiwi schema metadata at compile time. It is intentionally smaller
  than `NodeChange` so large scenes can be indexed without materializing every
  schema field.
  """

  @source_module FigKiwi.Schema.NodeChange
  @source_fields [:guid, :type, :name, :parent_index]
  @parent_index_source_fields [:guid, :position]

  @source_props @source_module.__kiwi_props__()
  @parent_index_props FigKiwi.Schema.ParentIndex.__kiwi_props__()

  for field <- @source_fields do
    unless Map.has_key?(@source_props.fields_by_name, field) do
      raise CompileError,
        description:
          "#{inspect(@source_module)} is missing required scene projection field #{inspect(field)}"
    end
  end

  for field <- @parent_index_source_fields do
    unless Map.has_key?(@parent_index_props.fields_by_name, field) do
      raise CompileError,
        description:
          "FigKiwi.Schema.ParentIndex is missing required scene projection field #{inspect(field)}"
    end
  end

  @enforce_keys [:guid, :node_type]
  defstruct [:guid, :node_type, :name, :parent_guid, :position, children: nil]

  @type t :: %__MODULE__{
          guid: String.t(),
          node_type: FigKiwi.Schema.NodeType.t() | String.t(),
          name: String.t() | nil,
          parent_guid: String.t() | nil,
          position: String.t() | nil,
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
  Returns the `ParentIndex` fields flattened into this projection.
  """
  @spec parent_index_source_fields() :: [atom()]
  def parent_index_source_fields, do: @parent_index_source_fields

  @doc false
  @spec from_map(map()) :: t()
  def from_map(map) when is_map(map) do
    struct!(__MODULE__, Map.take(map, [:guid, :node_type, :name, :parent_guid, :position]))
  end
end
