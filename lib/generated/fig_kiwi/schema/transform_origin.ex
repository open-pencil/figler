defmodule FigKiwi.Schema.TransformOrigin do
  @moduledoc "Generated Kiwi message module for `TransformOrigin`."
  use KiwiCodec, kind: :message
  field(:x, 1, type: FigKiwi.Schema.Number, source_name: "x")
  field(:y, 2, type: FigKiwi.Schema.Number, source_name: "y")
end
