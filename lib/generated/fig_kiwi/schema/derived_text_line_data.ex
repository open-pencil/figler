defmodule FigKiwi.Schema.DerivedTextLineData do
  @moduledoc "Generated Kiwi message module for `DerivedTextLineData`."
  use KiwiCodec, kind: :message

  field(:directionality, 1,
    type: {:enum, FigKiwi.Schema.Directionality},
    source_name: "directionality"
  )
end
