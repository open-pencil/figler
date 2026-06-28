defmodule Figler.Scene.Graph.Component.PropertyAssignment do
  alias Figler.Scene.Graph.GUID

  @moduledoc """
  Component property assignment metadata for graph resolution.
  """

  defstruct [:def_id, :value, :variable_value]

  @type t :: %__MODULE__{def_id: GUID.figma_guid() | nil, value: term(), variable_value: term()}
end
