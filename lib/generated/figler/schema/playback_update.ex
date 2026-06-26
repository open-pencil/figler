defmodule Figler.Schema.PlaybackUpdate do
  @moduledoc "Generated Kiwi message module for `PlaybackUpdate`."
  use KiwiCodec, kind: :message

  field(:last_top_level_change, 1,
    type: Figler.Schema.TopLevelPlaybackChange,
    source_name: "lastTopLevelChange"
  )

  field(:last_top_level_change_status, 2,
    type: Figler.Schema.PlaybackChangeKeyframe,
    source_name: "lastTopLevelChangeStatus"
  )

  field(:scroll_mappings, 3,
    repeated: true,
    type: Figler.Schema.ScrollMapping,
    source_name: "scrollMappings"
  )

  field(:timestamp, 4, type: :float, source_name: "timestamp")
  field(:pointer_location, 5, type: Figler.Schema.Vector, source_name: "pointerLocation")
  field(:is_top_level_frame_change, 6, type: :bool, source_name: "isTopLevelFrameChange")

  field(:state_mappings, 7,
    repeated: true,
    type: Figler.Schema.StateMapping,
    source_name: "stateMappings"
  )
end
