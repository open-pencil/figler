defmodule FigKiwi.Schema.TransformFnType do
  @moduledoc "Generated Kiwi enum module for `TransformFnType`."
  use KiwiCodec, kind: :enum
  enum_value(:none, 0)
  enum_value(:matrix_3_d, 1)
  enum_value(:perspective, 2)
  enum_value(:translate_z, 3)
  enum_value(:rotate_x, 4)
  enum_value(:rotate_y, 5)
  enum_value(:rotate_z, 6)
end
