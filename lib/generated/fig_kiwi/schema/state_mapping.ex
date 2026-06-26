defmodule FigKiwi.Schema.StateMapping do
  @moduledoc "Generated Kiwi message module for `StateMapping`."
  use KiwiCodec, kind: :message
  field(:stable_path, 1, type: FigKiwi.Schema.GUIDPath, source_name: "stablePath")

  field(:last_top_level_change, 2,
    type: FigKiwi.Schema.TopLevelPlaybackChange,
    source_name: "lastTopLevelChange"
  )

  field(:last_top_level_change_status, 3,
    type: FigKiwi.Schema.PlaybackChangeKeyframe,
    source_name: "lastTopLevelChangeStatus"
  )

  field(:timestamp, 4, type: :float, source_name: "timestamp")
end
