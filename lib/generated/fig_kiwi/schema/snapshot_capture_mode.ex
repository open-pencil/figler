defmodule FigKiwi.Schema.SnapshotCaptureMode do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:full, 0)
  enum_value(:partial, 1)
end
