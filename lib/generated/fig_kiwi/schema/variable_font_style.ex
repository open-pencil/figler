defmodule FigKiwi.Schema.VariableFontStyle do
  @moduledoc "Generated Kiwi message module for `VariableFontStyle`."
  use KiwiCodec, kind: :message
  field(:as_string, 1, type: FigKiwi.Schema.VariableData, source_name: "asString")
  field(:as_float, 2, type: FigKiwi.Schema.VariableData, source_name: "asFloat")
  field(:as_variations, 3, type: FigKiwi.Schema.VariableData, source_name: "asVariations")
end
