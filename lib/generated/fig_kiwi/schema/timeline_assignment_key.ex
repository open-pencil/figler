defmodule FigKiwi.Schema.TimelineAssignmentKey do
  @moduledoc "Generated Kiwi message module for `TimelineAssignmentKey`."
  use KiwiCodec, kind: :message
  field(:assigned_timeline_id, 1, type: FigKiwi.Schema.GUID, source_name: "assignedTimelineId")

  field(:containing_timeline_id, 2,
    type: FigKiwi.Schema.GUID,
    source_name: "containingTimelineId"
  )
end
