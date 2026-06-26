defmodule FigKiwi.Schema.Line do
  @moduledoc "Generated Kiwi message module for `Line`."
  use KiwiCodec, kind: :message
  field(:a, 1, type: FigKiwi.Schema.Vector, source_name: "a")
  field(:b, 2, type: FigKiwi.Schema.Vector, source_name: "b")
end
