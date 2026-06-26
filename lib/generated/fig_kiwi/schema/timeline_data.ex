defmodule FigKiwi.Schema.TimelineData do
  @moduledoc "Generated Kiwi message module for `TimelineData`."
  use KiwiCodec, kind: :message
  field(:duration_us, 1, type: :uint64, source_name: "durationUs")
  field(:default_timeline, 2, type: :bool, source_name: "defaultTimeline")
  field(:parent_timeline_def_id, 3, type: FigKiwi.Schema.GUID, source_name: "parentTimelineDefId")

  field(:playback_style, 4,
    type: {:enum, FigKiwi.Schema.PlaybackStyle},
    source_name: "playbackStyle"
  )
end
