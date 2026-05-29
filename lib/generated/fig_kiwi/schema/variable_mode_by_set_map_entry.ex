defmodule FigKiwi.Schema.VariableModeBySetMapEntry do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:variable_set_id, 1, type: FigKiwi.Schema.VariableSetID, source_name: "variableSetID")
  field(:variable_mode_id, 2, type: FigKiwi.Schema.GUID, source_name: "variableModeID")

  field(:variable_set_extension_id, 3,
    type: FigKiwi.Schema.VariableSetID,
    source_name: "variableSetExtensionID"
  )
end
