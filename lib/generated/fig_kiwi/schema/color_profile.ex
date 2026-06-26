defmodule FigKiwi.Schema.ColorProfile do
  @moduledoc "Generated Kiwi enum module for `ColorProfile`."
  use KiwiCodec, kind: :enum
  enum_value(:srgb, 0)
  enum_value(:display_p3, 1)
end
