defmodule FigKiwi.Schema.DiagramLayoutPaused do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:no, 0)
  enum_value(:yes, 1)
end
