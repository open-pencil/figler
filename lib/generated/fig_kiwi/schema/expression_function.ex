defmodule FigKiwi.Schema.ExpressionFunction do
  @moduledoc "Generated Kiwi enum module for `ExpressionFunction`."
  use KiwiCodec, kind: :enum
  enum_value(:addition, 0)
  enum_value(:subtraction, 1)
  enum_value(:resolve_variant, 2)
  enum_value(:multiply, 3)
  enum_value(:divide, 4)
  enum_value(:equals, 5)
  enum_value(:not_equal, 6)
  enum_value(:less_than, 7)
  enum_value(:less_than_or_equal, 8)
  enum_value(:greater_than, 9)
  enum_value(:greater_than_or_equal, 10)
  enum_value(:and, 11)
  enum_value(:or, 12)
  enum_value(:not, 13)
  enum_value(:stringify, 14)
  enum_value(:ternary, 15)
  enum_value(:var_mode_lookup, 16)
  enum_value(:negate, 17)
  enum_value(:is_truthy, 18)
  enum_value(:keyframe, 19)
end
