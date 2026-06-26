defmodule Figler.Schema.LineConfig do
  @moduledoc "Generated Kiwi message module for `LineConfig`."
  use KiwiCodec, kind: :message
  field(:mode, 1, type: {:enum, Figler.Schema.PointMode}, source_name: "mode")
  field(:unit, 2, type: {:enum, Figler.Schema.NumberUnits}, source_name: "unit")
end
