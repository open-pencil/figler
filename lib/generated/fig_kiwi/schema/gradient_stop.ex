defmodule FigKiwi.Schema.GradientStop do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:position, 1, type: :float, source_name: "position")
  field(:color, 2, type: FigKiwi.Schema.VariableData, source_name: "color")
end
