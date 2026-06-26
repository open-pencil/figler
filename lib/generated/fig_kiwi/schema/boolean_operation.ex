defmodule FigKiwi.Schema.BooleanOperation do
  @moduledoc "Generated Kiwi enum module for `BooleanOperation`."
  use KiwiCodec, kind: :enum
  enum_value(:union, 0)
  enum_value(:intersect, 1)
  enum_value(:subtract, 2)
  enum_value(:xor, 3)
end
