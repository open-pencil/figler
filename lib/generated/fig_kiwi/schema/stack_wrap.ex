defmodule FigKiwi.Schema.StackWrap do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:no_wrap, 0)
  enum_value(:wrap, 1)
end
