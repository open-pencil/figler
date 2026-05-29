defmodule FigKiwi.Schema.DerivedTextLineData do
  @moduledoc false
  use KiwiCodec, kind: :message

  field(:directionality, 1,
    type: {:enum, FigKiwi.Schema.Directionality},
    source_name: "directionality"
  )
end
