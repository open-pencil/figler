defmodule FigKiwi.Schema.PointRadiusConfig do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:mode, 1, type: {:enum, FigKiwi.Schema.PointMode}, source_name: "mode")
  field(:position_unit, 2, type: {:enum, FigKiwi.Schema.NumberUnits}, source_name: "positionUnit")
  field(:radius_unit, 3, type: {:enum, FigKiwi.Schema.NumberUnits}, source_name: "radiusUnit")
  field(:min_radius, 4, type: :float, source_name: "minRadius")
  field(:max_radius, 5, type: :float, source_name: "maxRadius")
end
