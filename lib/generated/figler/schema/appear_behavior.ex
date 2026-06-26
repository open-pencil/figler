defmodule Figler.Schema.AppearBehavior do
  @moduledoc "Generated Kiwi message module for `AppearBehavior`."
  use KiwiCodec, kind: :message
  field(:trigger, 1, type: {:enum, Figler.Schema.AppearBehaviorTrigger}, source_name: "trigger")
  field(:direction, 2, type: {:enum, Figler.Schema.RelativeDirection}, source_name: "direction")
  field(:other_layer, 3, type: Figler.Schema.GUID, source_name: "otherLayer")

  field(:enter_transition, 4,
    type: Figler.Schema.BehaviorTransition,
    source_name: "enterTransition"
  )

  field(:enter_state, 5, type: Figler.Schema.NodeChange, source_name: "enterState")

  field(:exit_transition, 6,
    type: Figler.Schema.BehaviorTransition,
    source_name: "exitTransition"
  )

  field(:exit_state, 7, type: Figler.Schema.NodeChange, source_name: "exitState")
  field(:plays_once, 8, type: :bool, source_name: "playsOnce")
  field(:plays_once_var, 9, type: Figler.Schema.VariableData, source_name: "playsOnceVar")
  field(:is_deleted, 10, type: :bool, source_name: "isDeleted")
end
