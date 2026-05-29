defmodule FigKiwi.Schema.VariableData do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:value, 1, type: FigKiwi.Schema.VariableAnyValue, source_name: "value")
  field(:data_type, 2, type: {:enum, FigKiwi.Schema.VariableDataType}, source_name: "dataType")

  field(:resolved_data_type, 3,
    type: {:enum, FigKiwi.Schema.VariableResolvedDataType},
    source_name: "resolvedDataType"
  )
end
