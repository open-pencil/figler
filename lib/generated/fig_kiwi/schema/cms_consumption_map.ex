defmodule FigKiwi.Schema.CMSConsumptionMap do
  @moduledoc false
  use KiwiCodec, kind: :message

  field(:entries, 1,
    repeated: true,
    type: FigKiwi.Schema.CMSConsumptionMapEntry,
    source_name: "entries"
  )
end
