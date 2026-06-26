defmodule FigKiwi.Schema.EasingType do
  @moduledoc "Generated Kiwi enum module for `EasingType`."
  use KiwiCodec, kind: :enum
  enum_value(:in_cubic, 0)
  enum_value(:out_cubic, 1)
  enum_value(:inout_cubic, 2)
  enum_value(:linear, 3)
  enum_value(:in_back_cubic, 4)
  enum_value(:out_back_cubic, 5)
  enum_value(:inout_back_cubic, 6)
  enum_value(:custom_cubic, 7)
  enum_value(:spring, 8)
  enum_value(:gentle_spring, 9)
  enum_value(:custom_spring, 10)
  enum_value(:spring_preset_one, 11)
  enum_value(:spring_preset_two, 12)
  enum_value(:spring_preset_three, 13)
  enum_value(:hold, 14)
end
