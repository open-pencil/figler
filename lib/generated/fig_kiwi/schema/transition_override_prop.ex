defmodule FigKiwi.Schema.TransitionOverrideProp do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:all, 0)
  enum_value(:opacity, 1)
  enum_value(:translation, 2)
  enum_value(:rotation, 3)
  enum_value(:scale, 4)
end
