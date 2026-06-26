defmodule FigKiwi.Schema.ColorPointConfig do
  @moduledoc "Generated Kiwi message module for `ColorPointConfig`."
  use KiwiCodec, kind: :message
  field(:mode, 1, type: {:enum, FigKiwi.Schema.PointMode}, source_name: "mode")
  field(:unit, 2, type: {:enum, FigKiwi.Schema.NumberUnits}, source_name: "unit")
end
