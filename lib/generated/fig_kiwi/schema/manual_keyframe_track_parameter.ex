defmodule FigKiwi.Schema.ManualKeyframeTrackParameter do
  @moduledoc false
  use KiwiCodec, kind: :message

  field(:keyframe_track_id, 1,
    type: FigKiwi.Schema.KeyframeTrackId,
    source_name: "keyframeTrackId"
  )

  field(:timeline_def_id, 2, type: FigKiwi.Schema.GUID, source_name: "timelineDefId")
end
