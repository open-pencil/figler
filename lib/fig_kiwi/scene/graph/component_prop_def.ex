defmodule FigKiwi.Scene.Graph.ComponentPropDef do
  alias FigKiwi.Scene.Graph.GUID

  @moduledoc """
  Component property definition metadata for graph resolution.
  """

  defstruct [:id, :name, :type, :initial_value]

  @type t :: %__MODULE__{
          id: GUID.figma_guid() | nil,
          name: String.t() | nil,
          type: atom() | integer() | nil,
          initial_value: term()
        }
end
