defmodule FigKiwi.Schema.OptionalVector do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:value, 1, type: FigKiwi.Schema.Vector, source_name: "value")
end
