defmodule FigKiwi.Schema.StrokeAlign do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:center, 0)
  enum_value(:inside, 1)
  enum_value(:outside, 2)
  enum_value(:offset, 3)
end
