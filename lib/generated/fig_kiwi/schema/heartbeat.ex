defmodule FigKiwi.Schema.Heartbeat do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:foreground, 0)
  enum_value(:background, 1)
end
