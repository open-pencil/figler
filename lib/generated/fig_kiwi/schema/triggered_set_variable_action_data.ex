defmodule FigKiwi.Schema.TriggeredSetVariableActionData do
  @moduledoc "Generated Kiwi message module for `TriggeredSetVariableActionData`."
  use KiwiCodec, kind: :message

  field(:node_for_finding_topmost_screen_id, 1,
    type: FigKiwi.Schema.GUID,
    source_name: "nodeForFindingTopmostScreenId"
  )

  field(:target_variable_id, 2, type: :string, source_name: "targetVariableId")
  field(:target_variable_data, 3, type: :string, source_name: "targetVariableData")
  field(:resolved_variable_modes, 4, type: :string, source_name: "resolvedVariableModes")
end
