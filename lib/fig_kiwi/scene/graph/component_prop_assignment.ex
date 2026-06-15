defmodule FigKiwi.Scene.Graph.ComponentPropAssignment do
  @moduledoc """
  Component property assignment metadata for graph resolution.
  """

  defstruct [:def_id, :value, :variable_value]

  @type t :: %__MODULE__{def_id: String.t() | nil, value: term(), variable_value: term()}
end
