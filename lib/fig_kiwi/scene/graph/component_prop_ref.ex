defmodule FigKiwi.Scene.Graph.ComponentPropRef do
  @moduledoc """
  Component property reference metadata for graph resolution.
  """

  defstruct [:def_id, :field]

  @type t :: %__MODULE__{def_id: String.t() | nil, field: String.t() | atom() | nil}
end
