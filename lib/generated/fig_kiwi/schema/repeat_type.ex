defmodule FigKiwi.Schema.RepeatType do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:linear, 0)
  enum_value(:radial, 1)
end
