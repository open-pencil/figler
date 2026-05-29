defmodule FigKiwi.Schema.DocumentColorProfile do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:legacy, 0)
  enum_value(:srgb, 1)
  enum_value(:display_p3, 2)
end
