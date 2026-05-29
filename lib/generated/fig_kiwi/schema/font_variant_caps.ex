defmodule FigKiwi.Schema.FontVariantCaps do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:normal, 0)
  enum_value(:small, 1)
  enum_value(:all_small, 2)
  enum_value(:petite, 3)
  enum_value(:all_petite, 4)
  enum_value(:unicase, 5)
  enum_value(:titling, 6)
end
