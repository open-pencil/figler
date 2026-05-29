defmodule FigKiwi.Schema.TimelineAssignmentsMap do
  @moduledoc false
  use KiwiCodec, kind: :message

  field(:entries, 1,
    repeated: true,
    type: FigKiwi.Schema.TimelineAssignmentsMapEntry,
    source_name: "entries"
  )
end
