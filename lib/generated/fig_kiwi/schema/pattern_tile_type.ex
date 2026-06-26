defmodule FigKiwi.Schema.PatternTileType do
  @moduledoc "Generated Kiwi enum module for `PatternTileType`."
  use KiwiCodec, kind: :enum
  enum_value(:rectangular, 0)
  enum_value(:horizontal_hexagonal, 1)
  enum_value(:vertical_hexagonal, 2)
end
