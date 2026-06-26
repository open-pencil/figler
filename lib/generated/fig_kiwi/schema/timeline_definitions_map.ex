defmodule FigKiwi.Schema.TimelineDefinitionsMap do
  @moduledoc "Generated Kiwi message module for `TimelineDefinitionsMap`."
  use KiwiCodec, kind: :message

  field(:entries, 1,
    repeated: true,
    type: FigKiwi.Schema.TimelineDefinitionsMapEntry,
    source_name: "entries"
  )
end
