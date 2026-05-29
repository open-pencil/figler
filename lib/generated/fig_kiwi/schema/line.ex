defmodule FigKiwi.Schema.Line do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:a, 1, type: FigKiwi.Schema.Vector, source_name: "a")
  field(:b, 2, type: FigKiwi.Schema.Vector, source_name: "b")
end
