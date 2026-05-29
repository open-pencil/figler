defmodule FigKiwi.Schema.AgendaMusicInfo do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:song_id, 1, type: :string, source_name: "songID")
  field(:start_time_ms, 2, type: :uint, source_name: "startTimeMs")
end
