defmodule FigKiwi.Schema.FontVariantNumericFraction do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:normal, 0)
  enum_value(:diagonal, 1)
  enum_value(:stacked, 2)
end
