defmodule Figler.Schema.ManualKeyframeTrackParameter do
  @moduledoc "Generated Kiwi message module for `ManualKeyframeTrackParameter`."
  use KiwiCodec, kind: :message

  field(:keyframe_track_id, 1,
    type: Figler.Schema.KeyframeTrackId,
    source_name: "keyframeTrackId"
  )

  field(:timeline_def_id, 2, type: Figler.Schema.GUID, source_name: "timelineDefId")
end
