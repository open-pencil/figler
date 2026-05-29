defmodule FigKiwi.Schema.ChildReadingDirection do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:none, 0)
  enum_value(:left_to_right, 1)
  enum_value(:right_to_left, 2)
end
