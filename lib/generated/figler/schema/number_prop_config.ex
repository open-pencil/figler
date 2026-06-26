defmodule Figler.Schema.NumberPropConfig do
  @moduledoc "Generated Kiwi message module for `NumberPropConfig`."
  use KiwiCodec, kind: :message
  field(:control, 1, type: {:enum, Figler.Schema.ParameterConfigControl}, source_name: "control")
  field(:min, 2, type: Figler.Schema.VariableData, source_name: "min")
  field(:max, 3, type: Figler.Schema.VariableData, source_name: "max")
  field(:step, 4, type: Figler.Schema.VariableData, source_name: "step")
end
