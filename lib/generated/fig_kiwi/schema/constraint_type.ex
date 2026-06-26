defmodule FigKiwi.Schema.ConstraintType do
  @moduledoc "Generated Kiwi enum module for `ConstraintType`."
  use KiwiCodec, kind: :enum
  enum_value(:min, 0)
  enum_value(:center, 1)
  enum_value(:max, 2)
  enum_value(:stretch, 3)
  enum_value(:scale, 4)
  enum_value(:fixed_min, 5)
  enum_value(:fixed_max, 6)
end
