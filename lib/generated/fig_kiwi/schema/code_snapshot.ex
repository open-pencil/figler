defmodule FigKiwi.Schema.CodeSnapshot do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:state, 6, type: {:enum, FigKiwi.Schema.CodeSnapshotState}, source_name: "state")
  field(:invalidated_at, 7, type: :uint, source_name: "invalidatedAt")
  field(:paints, 1, repeated: true, type: FigKiwi.Schema.Paint, source_name: "paints")
  field(:offset, 2, type: FigKiwi.Schema.Vector, source_name: "offset")
  field(:layout_size, 3, type: FigKiwi.Schema.Vector, source_name: "layoutSize")
  field(:canvas_size, 5, type: FigKiwi.Schema.Vector, source_name: "canvasSize")
  field(:device_pixel_ratio, 4, type: :uint, source_name: "devicePixelRatio")
end
