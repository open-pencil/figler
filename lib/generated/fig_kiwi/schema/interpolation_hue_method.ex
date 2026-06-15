defmodule FigKiwi.Schema.InterpolationHueMethod do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:shorter, 0)
  enum_value(:longer, 1)
  enum_value(:increasing, 2)
  enum_value(:decreasing, 3)
end
