defmodule Figler.Schema.SliderConfig do
  @moduledoc "Generated Kiwi message module for `SliderConfig`."
  use KiwiCodec, kind: :message
  field(:min, 1, type: Figler.Schema.VariableData, source_name: "min")
  field(:max, 2, type: Figler.Schema.VariableData, source_name: "max")
  field(:step, 3, type: Figler.Schema.VariableData, source_name: "step")
  field(:unit, 4, type: Figler.Schema.VariableData, source_name: "unit")
end
