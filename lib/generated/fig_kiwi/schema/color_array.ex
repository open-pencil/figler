defmodule FigKiwi.Schema.ColorArray do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:colors, 1, repeated: true, type: FigKiwi.Schema.VariableData, source_name: "colors")
end
