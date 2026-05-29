defmodule FigKiwi.Schema.TextTruncation do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:disabled, 0)
  enum_value(:ending, 1)
end
