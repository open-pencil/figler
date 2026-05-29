defmodule FigKiwi.Schema.StackSize do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:fixed, 0)
  enum_value(:resize_to_fit, 1)
  enum_value(:resize_to_fit_with_implicit_size, 2)
end
