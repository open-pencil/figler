defmodule Figler.Schema.TransformFn do
  @moduledoc "Generated Kiwi message module for `TransformFn`."
  use KiwiCodec, kind: :message
  field(:type, 1, type: {:enum, Figler.Schema.TransformFnType}, source_name: "type")
  field(:value, 2, type: Figler.Schema.TransformFnValue, source_name: "value")
end
