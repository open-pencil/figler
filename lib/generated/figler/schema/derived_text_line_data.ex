defmodule Figler.Schema.DerivedTextLineData do
  @moduledoc "Generated Kiwi message module for `DerivedTextLineData`."
  use KiwiCodec, kind: :message

  field(:directionality, 1,
    type: {:enum, Figler.Schema.Directionality},
    source_name: "directionality"
  )
end
