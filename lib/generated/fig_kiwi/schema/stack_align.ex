defmodule FigKiwi.Schema.StackAlign do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:min, 0)
  enum_value(:center, 1)
  enum_value(:max, 2)
  enum_value(:baseline, 3)
end
