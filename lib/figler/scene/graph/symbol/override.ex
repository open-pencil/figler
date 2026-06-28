defmodule Figler.Scene.Graph.Symbol.Override do
  alias Figler.Scene.Graph.Component.PropertyAssignment
  alias Figler.Scene.Graph.GUID

  @moduledoc """
  Structured symbol override metadata used by the Elixir graph resolver.
  """

  defstruct guid_path: [],
            overridden_symbol_id: nil,
            fields: %{},
            component_prop_assignments: [],
            variable_consumption: []

  @type t :: %__MODULE__{
          guid_path: [GUID.figma_guid()],
          overridden_symbol_id: GUID.figma_guid() | nil,
          fields: map(),
          component_prop_assignments: [PropertyAssignment.t()],
          variable_consumption: [term()]
        }
end
