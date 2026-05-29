defmodule FigKiwi.Schema.GridTrackSizingType do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:flex, 0)
  enum_value(:fixed, 1)
  enum_value(:hug, 2)
end
