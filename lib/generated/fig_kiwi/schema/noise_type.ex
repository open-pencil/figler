defmodule FigKiwi.Schema.NoiseType do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:multitone, 0)
  enum_value(:monotone, 1)
  enum_value(:duotone, 2)
end
