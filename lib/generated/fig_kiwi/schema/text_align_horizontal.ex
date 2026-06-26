defmodule FigKiwi.Schema.TextAlignHorizontal do
  @moduledoc "Generated Kiwi enum module for `TextAlignHorizontal`."
  use KiwiCodec, kind: :enum
  enum_value(:left, 0)
  enum_value(:center, 1)
  enum_value(:right, 2)
  enum_value(:justified, 3)
end
