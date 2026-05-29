defmodule FigKiwi.Schema.ColorStopVar do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:color, 1, type: FigKiwi.Schema.Color, source_name: "color")
  field(:color_var, 2, type: FigKiwi.Schema.VariableData, source_name: "colorVar")
  field(:position, 3, type: :float, source_name: "position")
end
