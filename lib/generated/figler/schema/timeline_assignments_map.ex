defmodule Figler.Schema.TimelineAssignmentsMap do
  @moduledoc "Generated Kiwi message module for `TimelineAssignmentsMap`."
  use KiwiCodec, kind: :message

  field(:entries, 1,
    repeated: true,
    type: Figler.Schema.TimelineAssignmentsMapEntry,
    source_name: "entries"
  )
end
