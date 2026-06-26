defmodule FigKiwi.Schema.AnimationPresetKeyframeTrackParameter do
  @moduledoc "Generated Kiwi message module for `AnimationPresetKeyframeTrackParameter`."
  use KiwiCodec, kind: :message

  field(:animation_preset_id, 1,
    type: FigKiwi.Schema.AnimationPresetId,
    source_name: "animationPresetId"
  )

  field(:keyframe_track_id, 2,
    type: FigKiwi.Schema.KeyframeTrackId,
    source_name: "keyframeTrackId"
  )

  field(:timeline_def_id, 3, type: FigKiwi.Schema.GUID, source_name: "timelineDefId")
end
