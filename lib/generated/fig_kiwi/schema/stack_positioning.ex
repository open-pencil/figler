defmodule FigKiwi.Schema.StackPositioning do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:auto, 0)
  enum_value(:absolute, 1)
end
