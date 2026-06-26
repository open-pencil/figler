defmodule FigKiwi.Schema.ColorArray do
  @moduledoc "Generated Kiwi message module for `ColorArray`."
  use KiwiCodec, kind: :message
  field(:colors, 1, repeated: true, type: FigKiwi.Schema.VariableData, source_name: "colors")
end
