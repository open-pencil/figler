defmodule FigKiwi.Schema.StyleType do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:none, 0)
  enum_value(:fill, 1)
  enum_value(:stroke, 2)
  enum_value(:text, 3)
  enum_value(:effect, 4)
  enum_value(:export, 5)
  enum_value(:grid, 6)
  enum_value(:animation, 7)
end
