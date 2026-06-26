defmodule FigKiwi.Schema.CMSConsumptionMap do
  @moduledoc "Generated Kiwi message module for `CMSConsumptionMap`."
  use KiwiCodec, kind: :message

  field(:entries, 1,
    repeated: true,
    type: FigKiwi.Schema.CMSConsumptionMapEntry,
    source_name: "entries"
  )
end
