defmodule FigKiwi.Schema.TimelinePositionType do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:absolute, 0)
  enum_value(:relative, 1)
end
