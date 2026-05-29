defmodule FigKiwi.Schema.FontVariantNumericFigure do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:normal, 0)
  enum_value(:lining, 1)
  enum_value(:oldstyle, 2)
end
