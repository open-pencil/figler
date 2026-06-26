defmodule FigKiwi.Schema.GradientStop do
  @moduledoc "Generated Kiwi message module for `GradientStop`."
  use KiwiCodec, kind: :message
  field(:position, 1, type: :float, source_name: "position")
  field(:color, 2, type: FigKiwi.Schema.VariableData, source_name: "color")
end
