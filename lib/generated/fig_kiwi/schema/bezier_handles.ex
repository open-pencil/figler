defmodule FigKiwi.Schema.BezierHandles do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:p1x, 1, type: :float, source_name: "p1x")
  field(:p1y, 2, type: :float, source_name: "p1y")
  field(:p2x, 3, type: :float, source_name: "p2x")
  field(:p2y, 4, type: :float, source_name: "p2y")
end
