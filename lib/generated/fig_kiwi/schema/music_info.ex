defmodule FigKiwi.Schema.MusicInfo do
  @moduledoc "Generated Kiwi message module for `MusicInfo`."
  use KiwiCodec, kind: :message
  field(:is_paused, 1, type: :bool, source_name: "isPaused")
  field(:message_id, 2, type: :uint, source_name: "messageID")
  field(:song_id, 3, type: :string, source_name: "songID")

  field(:last_received_song_timestamp_ms, 4,
    type: :uint,
    source_name: "lastReceivedSongTimestampMs"
  )

  field(:is_stopped, 5, type: :bool, source_name: "isStopped")
end
