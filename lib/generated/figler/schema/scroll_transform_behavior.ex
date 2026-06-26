defmodule Figler.Schema.ScrollTransformBehavior do
  @moduledoc "Generated Kiwi message module for `ScrollTransformBehavior`."
  use KiwiCodec, kind: :message

  field(:trigger, 1,
    type: {:enum, Figler.Schema.ScrollTransformBehaviorTrigger},
    source_name: "trigger"
  )

  field(:other_layer, 2, type: Figler.Schema.GUID, source_name: "otherLayer")
  field(:transition, 3, type: Figler.Schema.BehaviorTransition, source_name: "transition")
  field(:from_state, 4, type: Figler.Schema.NodeChange, source_name: "fromState")
  field(:to_state, 5, type: Figler.Schema.NodeChange, source_name: "toState")
  field(:plays_once, 6, type: :bool, source_name: "playsOnce")
  field(:plays_once_var, 7, type: :bool, source_name: "playsOnceVar")
  field(:plays_once_var2, 8, type: Figler.Schema.VariableData, source_name: "playsOnceVar2")
  field(:is_deleted, 9, type: :bool, source_name: "isDeleted")
end
