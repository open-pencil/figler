defmodule Figler.Schema.TransformOrigin do
  @moduledoc "Generated Kiwi message module for `TransformOrigin`."
  use KiwiCodec, kind: :message
  field(:x, 1, type: Figler.Schema.Number, source_name: "x")
  field(:y, 2, type: Figler.Schema.Number, source_name: "y")
end
