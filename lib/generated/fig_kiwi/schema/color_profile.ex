defmodule FigKiwi.Schema.ColorProfile do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:srgb, 0)
  enum_value(:display_p3, 1)
end
