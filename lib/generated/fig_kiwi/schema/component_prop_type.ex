defmodule FigKiwi.Schema.ComponentPropType do
  @moduledoc "Generated Kiwi enum module for `ComponentPropType`."
  use KiwiCodec, kind: :enum
  enum_value(:bool, 0)
  enum_value(:text, 1)
  enum_value(:color, 2)
  enum_value(:instance_swap, 3)
  enum_value(:variant, 4)
  enum_value(:number, 5)
  enum_value(:image, 6)
  enum_value(:slot, 7)
  enum_value(:easing, 8)
  enum_value(:color_array, 9)
  enum_value(:vector, 10)
  enum_value(:line, 11)
  enum_value(:circle, 12)
  enum_value(:rotation_3_d, 13)
  enum_value(:circle_point, 14)
  enum_value(:gradient, 15)
  enum_value(:color_point, 16)
end
