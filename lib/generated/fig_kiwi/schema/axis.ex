defmodule FigKiwi.Schema.Axis do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:x, 0)
  enum_value(:y, 1)
end
