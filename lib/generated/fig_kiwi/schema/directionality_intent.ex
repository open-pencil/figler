defmodule FigKiwi.Schema.DirectionalityIntent do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:implicit, 0)
  enum_value(:explicit, 1)
end
