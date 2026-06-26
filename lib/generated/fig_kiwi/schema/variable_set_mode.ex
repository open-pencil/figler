defmodule FigKiwi.Schema.VariableSetMode do
  @moduledoc "Generated Kiwi message module for `VariableSetMode`."
  use KiwiCodec, kind: :message
  field(:id, 1, type: FigKiwi.Schema.GUID, source_name: "id")
  field(:name, 2, type: :string, source_name: "name")
  field(:sort_position, 3, type: :string, source_name: "sortPosition")

  field(:parent_variable_set_id, 4,
    type: FigKiwi.Schema.VariableSetID,
    source_name: "parentVariableSetId"
  )

  field(:parent_mode_id, 5, type: FigKiwi.Schema.GUID, source_name: "parentModeId")
end
