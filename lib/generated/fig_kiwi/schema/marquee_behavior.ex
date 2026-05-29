defmodule FigKiwi.Schema.MarqueeBehavior do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:direction, 1, type: {:enum, FigKiwi.Schema.RelativeDirection}, source_name: "direction")
  field(:speed, 2, type: :float, source_name: "speed")
  field(:should_loop_infinitely, 3, type: :bool, source_name: "shouldLoopInfinitely")
  field(:speed_var, 4, type: FigKiwi.Schema.VariableData, source_name: "speedVar")

  field(:should_loop_infinitely_var, 5,
    type: FigKiwi.Schema.VariableData,
    source_name: "shouldLoopInfinitelyVar"
  )

  field(:pause_on_hover, 6, type: FigKiwi.Schema.VariableData, source_name: "pauseOnHover")
  field(:is_deleted, 7, type: :bool, source_name: "isDeleted")
end
