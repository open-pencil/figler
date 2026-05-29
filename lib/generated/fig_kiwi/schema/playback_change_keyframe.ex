defmodule FigKiwi.Schema.PlaybackChangeKeyframe do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:phase, 1, type: {:enum, FigKiwi.Schema.PlaybackChangePhase}, source_name: "phase")
  field(:progress, 2, type: :float, source_name: "progress")
  field(:timestamp, 3, type: :float, source_name: "timestamp")
end
