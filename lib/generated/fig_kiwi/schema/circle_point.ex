defmodule FigKiwi.Schema.CirclePoint do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:center, 1, type: FigKiwi.Schema.Vector, source_name: "center")
  field(:radius, 2, type: :float, source_name: "radius")
  field(:angle, 3, type: :float, source_name: "angle")
end
