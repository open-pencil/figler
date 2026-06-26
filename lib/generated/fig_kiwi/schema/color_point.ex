defmodule FigKiwi.Schema.ColorPoint do
  @moduledoc "Generated Kiwi message module for `ColorPoint`."
  use KiwiCodec, kind: :message
  field(:point, 1, type: FigKiwi.Schema.Vector, source_name: "point")
  field(:color, 2, type: FigKiwi.Schema.VariableData, source_name: "color")
end
