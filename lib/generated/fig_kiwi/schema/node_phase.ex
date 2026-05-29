defmodule FigKiwi.Schema.NodePhase do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:created, 0)
  enum_value(:removed, 1)
end
