defmodule FigKiwi.Schema.VariableTimingDisplayUnit do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:milliseconds, 0)
  enum_value(:seconds, 1)
end
