defmodule FigKiwi.Schema.BlurOpType do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:normal, 0)
  enum_value(:progressive, 1)
end
