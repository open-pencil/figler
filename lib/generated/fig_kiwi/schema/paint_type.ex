defmodule FigKiwi.Schema.PaintType do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:solid, 0)
  enum_value(:gradient_linear, 1)
  enum_value(:gradient_radial, 2)
  enum_value(:gradient_angular, 3)
  enum_value(:gradient_diamond, 4)
  enum_value(:image, 5)
  enum_value(:emoji, 6)
  enum_value(:video, 7)
  enum_value(:pattern, 8)
  enum_value(:noise, 9)
  enum_value(:custom, 10)
end
