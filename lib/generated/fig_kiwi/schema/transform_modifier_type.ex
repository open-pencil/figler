defmodule FigKiwi.Schema.TransformModifierType do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:repeat, 0)
  enum_value(:symmetry, 1)
  enum_value(:skew, 2)
end
