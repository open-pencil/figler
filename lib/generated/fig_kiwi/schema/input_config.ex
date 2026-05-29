defmodule FigKiwi.Schema.InputConfig do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:unit, 1, type: FigKiwi.Schema.VariableData, source_name: "unit")
  field(:min, 2, type: FigKiwi.Schema.VariableData, source_name: "min")
  field(:max, 3, type: FigKiwi.Schema.VariableData, source_name: "max")
end
