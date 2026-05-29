defmodule FigKiwi.Schema.PlaybackChangePhase do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:initiated, 0)
  enum_value(:aborted, 1)
  enum_value(:committed, 2)
end
