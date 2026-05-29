defmodule FigKiwi.Schema.TriggerComponentType do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:banner, 0)
  enum_value(:tag, 1)
end
