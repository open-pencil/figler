defmodule Figler.Schema.VariableDataValuesEntry do
  @moduledoc "Generated Kiwi message module for `VariableDataValuesEntry`."
  use KiwiCodec, kind: :message
  field(:mode_id, 1, type: Figler.Schema.GUID, source_name: "modeID")
  field(:variable_data, 2, type: Figler.Schema.VariableData, source_name: "variableData")
end
