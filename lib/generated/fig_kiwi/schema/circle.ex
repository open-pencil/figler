defmodule FigKiwi.Schema.Circle do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:center, 1, type: FigKiwi.Schema.Vector, source_name: "center")
  field(:radius, 2, type: :float, source_name: "radius")
end
