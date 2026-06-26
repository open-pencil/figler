defmodule FigKiwi.Schema.DynamicStrokeSettings do
  @moduledoc "Generated Kiwi message module for `DynamicStrokeSettings`."
  use KiwiCodec, kind: :message
  field(:frequency, 1, type: :float, source_name: "frequency")
  field(:wiggle, 2, type: :float, source_name: "wiggle")
  field(:smoothen, 3, type: :float, source_name: "smoothen")
end
