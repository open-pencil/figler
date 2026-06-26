defmodule FigKiwi.Schema.OptionalVector do
  @moduledoc "Generated Kiwi message module for `OptionalVector`."
  use KiwiCodec, kind: :message
  field(:value, 1, type: FigKiwi.Schema.Vector, source_name: "value")
end
