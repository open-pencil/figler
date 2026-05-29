defmodule FigKiwi.Schema.LayoutGridPattern do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:stripes, 0)
  enum_value(:grid, 1)
end
