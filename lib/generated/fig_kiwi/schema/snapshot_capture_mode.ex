defmodule FigKiwi.Schema.SnapshotCaptureMode do
  @moduledoc "Generated Kiwi enum module for `SnapshotCaptureMode`."
  use KiwiCodec, kind: :enum
  enum_value(:full, 0)
  enum_value(:partial, 1)
end
