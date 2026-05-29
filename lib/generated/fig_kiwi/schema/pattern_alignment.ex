defmodule FigKiwi.Schema.PatternAlignment do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:start, 0)
  enum_value(:center, 1)
  enum_value(:end, 2)
end
