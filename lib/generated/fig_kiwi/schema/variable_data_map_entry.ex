defmodule FigKiwi.Schema.VariableDataMapEntry do
  @moduledoc "Generated Kiwi message module for `VariableDataMapEntry`."
  use KiwiCodec, kind: :message
  field(:node_field, 1, type: :uint, source_name: "nodeField")
  field(:variable_data, 2, type: FigKiwi.Schema.VariableData, source_name: "variableData")

  field(:variable_field, 3,
    type: {:enum, FigKiwi.Schema.VariableField},
    source_name: "variableField"
  )
end
