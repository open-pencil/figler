defmodule Figler.Schema.TimelineDefinitionsMap do
  @moduledoc "Generated Kiwi message module for `TimelineDefinitionsMap`."
  use KiwiCodec, kind: :message

  field(:entries, 1,
    repeated: true,
    type: Figler.Schema.TimelineDefinitionsMapEntry,
    source_name: "entries"
  )
end
