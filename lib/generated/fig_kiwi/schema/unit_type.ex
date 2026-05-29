defmodule FigKiwi.Schema.UnitType do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:pixels, 0)
  enum_value(:relative, 1)
end
