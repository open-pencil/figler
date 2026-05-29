defmodule FigKiwi.Schema.AprilFunCursor do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:id, 1, type: :string, source_name: "id")
  field(:trail_enabled, 2, type: :bool, source_name: "trailEnabled")
end
