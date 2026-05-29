defmodule FigKiwi.Schema.EffectAxis do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:x, 0)
  enum_value(:y, 1)
  enum_value(:x_and_y, 2)
end
