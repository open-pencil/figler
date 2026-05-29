defmodule FigKiwi.Schema.ManagedStringNodeType do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:text, 0)
  enum_value(:concatenate, 1)
  enum_value(:plural, 2)
  enum_value(:placeholder, 3)
end
