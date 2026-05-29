defmodule FigKiwi.Schema.StyleSetContentType do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:solid, 0)
  enum_value(:gradient, 1)
  enum_value(:image, 2)
end
