defmodule FigKiwi.Schema.TimerInfo do
  @moduledoc "Generated Kiwi message module for `TimerInfo`."
  use KiwiCodec, kind: :message
  field(:is_paused, 1, type: :bool, source_name: "isPaused")
  field(:time_remaining_ms, 2, type: :uint, source_name: "timeRemainingMs")
  field(:total_time_ms, 3, type: :uint, source_name: "totalTimeMs")
  field(:timer_id, 4, type: :uint, source_name: "timerID")
  field(:set_by, 5, type: :string, source_name: "setBy")
  field(:song_id, 6, type: :uint, source_name: "songID")

  field(:last_received_song_timestamp_ms, 7,
    type: :uint,
    source_name: "lastReceivedSongTimestampMs"
  )

  field(:song_uuid, 8, type: :string, source_name: "songUUID")
end
