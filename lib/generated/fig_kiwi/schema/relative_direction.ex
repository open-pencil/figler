defmodule FigKiwi.Schema.RelativeDirection do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:up, 1)
  enum_value(:down, 2)
  enum_value(:left, 3)
  enum_value(:right, 4)
end
