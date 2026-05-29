defmodule FigKiwi.Schema.NumberVector2D do
  @moduledoc false
  use KiwiCodec, kind: :struct
  field(:x, 1, type: FigKiwi.Schema.Number, source_name: "x")
  field(:y, 2, type: FigKiwi.Schema.Number, source_name: "y")
end
