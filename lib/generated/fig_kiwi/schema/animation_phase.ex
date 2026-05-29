defmodule FigKiwi.Schema.AnimationPhase do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:in, 0)
  enum_value(:out, 1)
end
