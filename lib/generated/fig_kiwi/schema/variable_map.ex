defmodule FigKiwi.Schema.VariableMap do
  @moduledoc "Generated Kiwi message module for `VariableMap`."
  use KiwiCodec, kind: :message
  field(:values, 1, repeated: true, type: FigKiwi.Schema.VariableMapValue, source_name: "values")
end
