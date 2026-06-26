defmodule Figler.Schema.PlaybackChangeKeyframe do
  @moduledoc "Generated Kiwi message module for `PlaybackChangeKeyframe`."
  use KiwiCodec, kind: :message
  field(:phase, 1, type: {:enum, Figler.Schema.PlaybackChangePhase}, source_name: "phase")
  field(:progress, 2, type: :float, source_name: "progress")
  field(:timestamp, 3, type: :float, source_name: "timestamp")
end
