defmodule Figler.Schema.VariableMap do
  @moduledoc "Generated Kiwi message module for `VariableMap`."
  use KiwiCodec, kind: :message
  field(:values, 1, repeated: true, type: Figler.Schema.VariableMapValue, source_name: "values")
end
