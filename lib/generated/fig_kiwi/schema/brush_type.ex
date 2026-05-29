defmodule FigKiwi.Schema.BrushType do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:stretch, 0)
  enum_value(:scatter, 1)
end
