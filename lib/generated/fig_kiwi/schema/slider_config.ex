defmodule FigKiwi.Schema.SliderConfig do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:min, 1, type: FigKiwi.Schema.VariableData, source_name: "min")
  field(:max, 2, type: FigKiwi.Schema.VariableData, source_name: "max")
  field(:step, 3, type: FigKiwi.Schema.VariableData, source_name: "step")
  field(:unit, 4, type: FigKiwi.Schema.VariableData, source_name: "unit")
end
