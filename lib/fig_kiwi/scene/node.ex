defmodule FigKiwi.Scene.Node do
  @moduledoc """
  Lightweight projected scene node.
  """

  @enforce_keys [:guid, :node_type]
  defstruct [:guid, :node_type, :name, :parent_guid, :position, children: nil]

  @type t :: %__MODULE__{
          guid: String.t(),
          node_type: String.t(),
          name: String.t() | nil,
          parent_guid: String.t() | nil,
          position: String.t() | nil,
          children: [t()] | nil
        }

  @doc false
  @spec from_map(map()) :: t()
  def from_map(map) when is_map(map) do
    struct!(__MODULE__, Map.take(map, [:guid, :node_type, :name, :parent_guid, :position]))
  end
end
