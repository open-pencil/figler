defmodule Figler.Schema.InputConfig do
  @moduledoc "Generated Kiwi message module for `InputConfig`."
  use KiwiCodec, kind: :message
  field(:unit, 1, type: Figler.Schema.VariableData, source_name: "unit")
  field(:min, 2, type: Figler.Schema.VariableData, source_name: "min")
  field(:max, 3, type: Figler.Schema.VariableData, source_name: "max")
end
