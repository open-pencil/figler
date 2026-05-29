defmodule FigKiwi.Schema.NumberUnits do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:raw, 0)
  enum_value(:pixels, 1)
  enum_value(:percent, 2)
end
