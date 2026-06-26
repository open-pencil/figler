defmodule FigKiwi.Schema.PaintFilterMessage do
  @moduledoc "Generated Kiwi message module for `PaintFilterMessage`."
  use KiwiCodec, kind: :message
  field(:tint, 1, type: :float, source_name: "tint")
  field(:shadows, 2, type: :float, source_name: "shadows")
  field(:highlights, 3, type: :float, source_name: "highlights")
  field(:detail, 4, type: :float, source_name: "detail")
  field(:exposure, 5, type: :float, source_name: "exposure")
  field(:vignette, 6, type: :float, source_name: "vignette")
  field(:temperature, 7, type: :float, source_name: "temperature")
  field(:vibrance, 8, type: :float, source_name: "vibrance")
  field(:contrast, 9, type: :float, source_name: "contrast")
  field(:brightness, 10, type: :float, source_name: "brightness")
end
