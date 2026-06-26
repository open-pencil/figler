defmodule FigKiwi.Schema.NumberPropConfig do
  @moduledoc "Generated Kiwi message module for `NumberPropConfig`."
  use KiwiCodec, kind: :message
  field(:control, 1, type: {:enum, FigKiwi.Schema.ParameterConfigControl}, source_name: "control")
  field(:min, 2, type: FigKiwi.Schema.VariableData, source_name: "min")
  field(:max, 3, type: FigKiwi.Schema.VariableData, source_name: "max")
  field(:step, 4, type: FigKiwi.Schema.VariableData, source_name: "step")
end
