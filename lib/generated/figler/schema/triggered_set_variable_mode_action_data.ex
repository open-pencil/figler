defmodule Figler.Schema.TriggeredSetVariableModeActionData do
  @moduledoc "Generated Kiwi message module for `TriggeredSetVariableModeActionData`."
  use KiwiCodec, kind: :message

  field(:node_for_finding_topmost_screen_id, 1,
    type: Figler.Schema.GUID,
    source_name: "nodeForFindingTopmostScreenId"
  )

  field(:target_variable_set_key, 2, type: :string, source_name: "targetVariableSetKey")
  field(:target_variable_mode_id, 3, type: :string, source_name: "targetVariableModeId")

  field(:target_variable_set_id, 4,
    type: Figler.Schema.VariableSetID,
    source_name: "targetVariableSetId"
  )
end
