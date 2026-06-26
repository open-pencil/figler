defmodule FigKiwi.Schema.KeyframeAnyValue do
  @moduledoc "Generated Kiwi message module for `KeyframeAnyValue`."
  use KiwiCodec, kind: :message
  field(:float_value, 1, type: :float, source_name: "floatValue")
  field(:color_value, 2, type: FigKiwi.Schema.Color, source_name: "colorValue")
  field(:text_data_value, 3, type: FigKiwi.Schema.TextData, source_name: "textDataValue")
  field(:vector_value, 4, type: FigKiwi.Schema.Vector, source_name: "vectorValue")
end
