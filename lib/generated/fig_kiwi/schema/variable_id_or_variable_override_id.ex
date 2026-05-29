defmodule FigKiwi.Schema.VariableIdOrVariableOverrideId do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:variable_id, 1, type: FigKiwi.Schema.VariableID, source_name: "variableId")

  field(:variable_override_id, 2,
    type: FigKiwi.Schema.VariableOverrideId,
    source_name: "variableOverrideId"
  )
end
