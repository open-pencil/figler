defmodule Figler.Schema.VariableSetMode do
  @moduledoc "Generated Kiwi message module for `VariableSetMode`."
  use KiwiCodec, kind: :message
  field(:id, 1, type: Figler.Schema.GUID, source_name: "id")
  field(:name, 2, type: :string, source_name: "name")
  field(:sort_position, 3, type: :string, source_name: "sortPosition")

  field(:parent_variable_set_id, 4,
    type: Figler.Schema.VariableSetID,
    source_name: "parentVariableSetId"
  )

  field(:parent_mode_id, 5, type: Figler.Schema.GUID, source_name: "parentModeId")
end
