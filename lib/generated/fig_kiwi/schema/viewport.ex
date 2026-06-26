defmodule FigKiwi.Schema.Viewport do
  @moduledoc "Generated Kiwi message module for `Viewport`."
  use KiwiCodec, kind: :message
  field(:canvas_space_bounds, 1, type: FigKiwi.Schema.Rect, source_name: "canvasSpaceBounds")
  field(:pixel_preview, 2, type: :bool, source_name: "pixelPreview")
  field(:pixel_density, 3, type: :float, source_name: "pixelDensity")
  field(:canvas_guid, 4, type: FigKiwi.Schema.GUID, source_name: "canvasGuid")
end
