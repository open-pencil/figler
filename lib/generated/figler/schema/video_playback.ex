defmodule Figler.Schema.VideoPlayback do
  @moduledoc "Generated Kiwi message module for `VideoPlayback`."
  use KiwiCodec, kind: :message
  field(:autoplay, 1, type: :bool, source_name: "autoplay")
  field(:media_loop, 2, type: :bool, source_name: "mediaLoop")
  field(:muted, 3, type: :bool, source_name: "muted")
  field(:show_controls, 4, type: :bool, source_name: "showControls")
  field(:start_time_ms, 5, type: :uint, source_name: "startTimeMs")
  field(:end_time_ms, 6, type: :uint, source_name: "endTimeMs")
end
