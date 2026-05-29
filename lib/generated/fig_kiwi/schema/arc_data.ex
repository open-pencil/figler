defmodule FigKiwi.Schema.ArcData do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:starting_angle, 1, type: :float, source_name: "startingAngle")
  field(:ending_angle, 2, type: :float, source_name: "endingAngle")
  field(:inner_radius, 3, type: :float, source_name: "innerRadius")
end
