defmodule FigKiwi.Schema.StretchStrokeSettings do
  @moduledoc false
  use KiwiCodec, kind: :message

  field(:orientation, 1,
    type: {:enum, FigKiwi.Schema.BrushOrientation},
    source_name: "orientation"
  )
end
