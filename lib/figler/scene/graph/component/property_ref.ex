defmodule Figler.Scene.Graph.Component.PropertyRef do
  alias Figler.Scene.Graph.GUID

  @moduledoc """
  Component property reference metadata for graph resolution.
  """

  defstruct [:def_id, :field]

  @type t :: %__MODULE__{def_id: GUID.figma_guid() | nil, field: String.t() | atom() | nil}
end
