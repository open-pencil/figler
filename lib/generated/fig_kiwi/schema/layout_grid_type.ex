defmodule FigKiwi.Schema.LayoutGridType do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:min, 0)
  enum_value(:center, 1)
  enum_value(:stretch, 2)
  enum_value(:max, 3)
end
