defmodule FigKiwi.Schema.Rect do
  @moduledoc false
  use KiwiCodec, kind: :struct
  field(:x, 1, type: :float, source_name: "x")
  field(:y, 2, type: :float, source_name: "y")
  field(:w, 3, type: :float, source_name: "w")
  field(:h, 4, type: :float, source_name: "h")
end
