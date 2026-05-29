defmodule FigKiwi.Schema.BrushOrientation do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:forward, 0)
  enum_value(:reverse, 1)
end
