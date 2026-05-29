defmodule FigKiwi.Schema.InterpolationType do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:hold, 0)
  enum_value(:bezier, 1)
  enum_value(:spring, 2)
end
