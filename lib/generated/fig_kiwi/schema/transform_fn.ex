defmodule FigKiwi.Schema.TransformFn do
  @moduledoc "Generated Kiwi message module for `TransformFn`."
  use KiwiCodec, kind: :message
  field(:type, 1, type: {:enum, FigKiwi.Schema.TransformFnType}, source_name: "type")
  field(:value, 2, type: FigKiwi.Schema.TransformFnValue, source_name: "value")
end
