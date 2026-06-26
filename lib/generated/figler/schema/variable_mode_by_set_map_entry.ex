defmodule Figler.Schema.VariableModeBySetMapEntry do
  @moduledoc "Generated Kiwi message module for `VariableModeBySetMapEntry`."
  use KiwiCodec, kind: :message
  field(:variable_set_id, 1, type: Figler.Schema.VariableSetID, source_name: "variableSetID")
  field(:variable_mode_id, 2, type: Figler.Schema.GUID, source_name: "variableModeID")

  field(:variable_set_extension_id, 3,
    type: Figler.Schema.VariableSetID,
    source_name: "variableSetExtensionID"
  )
end
