defmodule FigKiwi.Scene.Graph.SymbolOverride do
  @moduledoc """
  Structured symbol override metadata used by the Elixir graph resolver.
  """

  defstruct guid_path: [],
            overridden_symbol_id: nil,
            fields: %{},
            component_prop_assignments: [],
            variable_consumption: []

  @type t :: %__MODULE__{
          guid_path: [String.t()],
          overridden_symbol_id: String.t() | nil,
          fields: map(),
          component_prop_assignments: [FigKiwi.Scene.Graph.ComponentPropAssignment.t()],
          variable_consumption: [term()]
        }
end
