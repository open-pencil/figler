defmodule FigKiwi.Schema.PlaybackStyle do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:once, 0)
  enum_value(:loop, 1)
  enum_value(:boomerang, 2)
end
