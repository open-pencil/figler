defmodule FigKiwi.Schema.PlaybackUpdate do
  @moduledoc false
  use KiwiCodec, kind: :message

  field(:last_top_level_change, 1,
    type: FigKiwi.Schema.TopLevelPlaybackChange,
    source_name: "lastTopLevelChange"
  )

  field(:last_top_level_change_status, 2,
    type: FigKiwi.Schema.PlaybackChangeKeyframe,
    source_name: "lastTopLevelChangeStatus"
  )

  field(:scroll_mappings, 3,
    repeated: true,
    type: FigKiwi.Schema.ScrollMapping,
    source_name: "scrollMappings"
  )

  field(:timestamp, 4, type: :float, source_name: "timestamp")
  field(:pointer_location, 5, type: FigKiwi.Schema.Vector, source_name: "pointerLocation")
  field(:is_top_level_frame_change, 6, type: :bool, source_name: "isTopLevelFrameChange")

  field(:state_mappings, 7,
    repeated: true,
    type: FigKiwi.Schema.StateMapping,
    source_name: "stateMappings"
  )
end
