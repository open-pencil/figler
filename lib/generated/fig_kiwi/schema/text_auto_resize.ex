defmodule FigKiwi.Schema.TextAutoResize do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:none, 0)
  enum_value(:width_and_height, 1)
  enum_value(:height, 2)
end
