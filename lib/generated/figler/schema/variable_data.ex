defmodule Figler.Schema.VariableData do
  @moduledoc "Generated Kiwi message module for `VariableData`."
  use KiwiCodec, kind: :message
  field(:value, 1, type: Figler.Schema.VariableAnyValue, source_name: "value")
  field(:data_type, 2, type: {:enum, Figler.Schema.VariableDataType}, source_name: "dataType")

  field(:resolved_data_type, 3,
    type: {:enum, Figler.Schema.VariableResolvedDataType},
    source_name: "resolvedDataType"
  )
end
