defmodule Figler.Schema.CodeSnapshot do
  @moduledoc "Generated Kiwi message module for `CodeSnapshot`."
  use KiwiCodec, kind: :message
  field(:state, 6, type: {:enum, Figler.Schema.CodeSnapshotState}, source_name: "state")
  field(:invalidated_at, 7, type: :uint, source_name: "invalidatedAt")
  field(:paints, 1, repeated: true, type: Figler.Schema.Paint, source_name: "paints")
  field(:offset, 2, type: Figler.Schema.Vector, source_name: "offset")
  field(:layout_size, 3, type: Figler.Schema.Vector, source_name: "layoutSize")
  field(:canvas_size, 5, type: Figler.Schema.Vector, source_name: "canvasSize")
  field(:device_pixel_ratio, 4, type: :uint, source_name: "devicePixelRatio")
end
