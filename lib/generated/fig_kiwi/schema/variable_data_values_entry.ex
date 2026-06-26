defmodule FigKiwi.Schema.VariableDataValuesEntry do
  @moduledoc "Generated Kiwi message module for `VariableDataValuesEntry`."
  use KiwiCodec, kind: :message
  field(:mode_id, 1, type: FigKiwi.Schema.GUID, source_name: "modeID")
  field(:variable_data, 2, type: FigKiwi.Schema.VariableData, source_name: "variableData")
end
