defmodule FigKiwi.Schema.Access do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:read_only, 0)
  enum_value(:read_write, 1)
end
