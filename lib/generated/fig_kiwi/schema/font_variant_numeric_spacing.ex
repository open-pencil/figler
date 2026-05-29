defmodule FigKiwi.Schema.FontVariantNumericSpacing do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:normal, 0)
  enum_value(:proportional, 1)
  enum_value(:tabular, 2)
end
