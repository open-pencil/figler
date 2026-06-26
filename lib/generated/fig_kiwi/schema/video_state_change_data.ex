defmodule FigKiwi.Schema.VideoStateChangeData do
  @moduledoc "Generated Kiwi message module for `VideoStateChangeData`."
  use KiwiCodec, kind: :message
  field(:target_node_id, 1, type: FigKiwi.Schema.GUID, source_name: "targetNodeId")
  field(:is_playing, 2, type: :bool, source_name: "isPlaying")
  field(:is_playing_sound, 3, type: :bool, source_name: "isPlayingSound")
  field(:current_times, 4, repeated: true, type: :uint, source_name: "currentTimes")
  field(:action_taken_timestamp, 5, type: :uint, source_name: "actionTakenTimestamp")
end
