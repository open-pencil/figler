defmodule FigKiwi.Schema.EffectType do
  @moduledoc "Generated Kiwi enum module for `EffectType`."
  use KiwiCodec, kind: :enum
  enum_value(:inner_shadow, 0)
  enum_value(:drop_shadow, 1)
  enum_value(:foreground_blur, 2)
  enum_value(:background_blur, 3)
  enum_value(:repeat, 4)
  enum_value(:symmetry, 5)
  enum_value(:grain, 6)
  enum_value(:noise, 7)
  enum_value(:glass, 8)
  enum_value(:custom, 9)
end
