defmodule FigKiwi.Schema.EffectAxis do
  @moduledoc "Generated Kiwi enum module for `EffectAxis`."
  use KiwiCodec, kind: :enum
  enum_value(:x, 0)
  enum_value(:y, 1)
  enum_value(:x_and_y, 2)
end
