defmodule FigKiwi.Schema.TimelineDefinitionsMap do
  @moduledoc false
  use KiwiCodec, kind: :message

  field(:entries, 1,
    repeated: true,
    type: FigKiwi.Schema.TimelineDefinitionsMapEntry,
    source_name: "entries"
  )
end
