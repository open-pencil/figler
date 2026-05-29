defmodule FigKiwi.Schema.WindingRule do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:nonzero, 0)
  enum_value(:odd, 1)
end
