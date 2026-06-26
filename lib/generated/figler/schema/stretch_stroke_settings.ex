defmodule Figler.Schema.StretchStrokeSettings do
  @moduledoc "Generated Kiwi message module for `StretchStrokeSettings`."
  use KiwiCodec, kind: :message

  field(:orientation, 1,
    type: {:enum, Figler.Schema.BrushOrientation},
    source_name: "orientation"
  )
end
