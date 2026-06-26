defmodule Figler.Schema.BlendMode do
  @moduledoc "Generated Kiwi enum module for `BlendMode`."
  use KiwiCodec, kind: :enum
  enum_value(:pass_through, 0)
  enum_value(:normal, 1)
  enum_value(:darken, 2)
  enum_value(:multiply, 3)
  enum_value(:linear_burn, 4)
  enum_value(:color_burn, 5)
  enum_value(:lighten, 6)
  enum_value(:screen, 7)
  enum_value(:linear_dodge, 8)
  enum_value(:color_dodge, 9)
  enum_value(:overlay, 10)
  enum_value(:soft_light, 11)
  enum_value(:hard_light, 12)
  enum_value(:difference, 13)
  enum_value(:exclusion, 14)
  enum_value(:hue, 15)
  enum_value(:saturation, 16)
  enum_value(:color, 17)
  enum_value(:luminosity, 18)
end
