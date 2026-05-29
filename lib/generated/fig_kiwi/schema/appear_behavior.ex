defmodule FigKiwi.Schema.AppearBehavior do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:trigger, 1, type: {:enum, FigKiwi.Schema.AppearBehaviorTrigger}, source_name: "trigger")
  field(:direction, 2, type: {:enum, FigKiwi.Schema.RelativeDirection}, source_name: "direction")
  field(:other_layer, 3, type: FigKiwi.Schema.GUID, source_name: "otherLayer")

  field(:enter_transition, 4,
    type: FigKiwi.Schema.BehaviorTransition,
    source_name: "enterTransition"
  )

  field(:enter_state, 5, type: FigKiwi.Schema.NodeChange, source_name: "enterState")

  field(:exit_transition, 6,
    type: FigKiwi.Schema.BehaviorTransition,
    source_name: "exitTransition"
  )

  field(:exit_state, 7, type: FigKiwi.Schema.NodeChange, source_name: "exitState")
  field(:plays_once, 8, type: :bool, source_name: "playsOnce")
  field(:plays_once_var, 9, type: FigKiwi.Schema.VariableData, source_name: "playsOnceVar")
  field(:is_deleted, 10, type: :bool, source_name: "isDeleted")
end
