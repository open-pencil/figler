defmodule FigKiwi.Schema.PatternTileType do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:rectangular, 0)
  enum_value(:horizontal_hexagonal, 1)
  enum_value(:vertical_hexagonal, 2)
end
