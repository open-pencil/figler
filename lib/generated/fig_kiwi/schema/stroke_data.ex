defmodule FigKiwi.Schema.StrokeData do
  @moduledoc "Generated Kiwi message module for `StrokeData`."
  use KiwiCodec, kind: :message
  field(:strokes, 1, repeated: true, type: FigKiwi.Schema.Stroke, source_name: "strokes")
  field(:version, 2, type: :uint, source_name: "version")
end
