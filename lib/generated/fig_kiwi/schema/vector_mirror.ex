defmodule FigKiwi.Schema.VectorMirror do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:none, 0)
  enum_value(:angle, 1)
  enum_value(:angle_and_length, 2)
end
