defmodule FigKiwi.Schema.ScrollTransformBehavior do
  @moduledoc false
  use KiwiCodec, kind: :message

  field(:trigger, 1,
    type: {:enum, FigKiwi.Schema.ScrollTransformBehaviorTrigger},
    source_name: "trigger"
  )

  field(:other_layer, 2, type: FigKiwi.Schema.GUID, source_name: "otherLayer")
  field(:transition, 3, type: FigKiwi.Schema.BehaviorTransition, source_name: "transition")
  field(:from_state, 4, type: FigKiwi.Schema.NodeChange, source_name: "fromState")
  field(:to_state, 5, type: FigKiwi.Schema.NodeChange, source_name: "toState")
  field(:plays_once, 6, type: :bool, source_name: "playsOnce")
  field(:plays_once_var, 7, type: :bool, source_name: "playsOnceVar")
  field(:plays_once_var2, 8, type: FigKiwi.Schema.VariableData, source_name: "playsOnceVar2")
  field(:is_deleted, 9, type: :bool, source_name: "isDeleted")
end
