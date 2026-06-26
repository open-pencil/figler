defmodule Figler.Schema.AprilFunCursor do
  @moduledoc "Generated Kiwi message module for `AprilFunCursor`."
  use KiwiCodec, kind: :message
  field(:id, 1, type: :string, source_name: "id")
  field(:trail_enabled, 2, type: :bool, source_name: "trailEnabled")
end
