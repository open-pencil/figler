defmodule FigKiwi.Schema.StackCounterAlignContent do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:auto, 0)
  enum_value(:space_between, 1)
end
