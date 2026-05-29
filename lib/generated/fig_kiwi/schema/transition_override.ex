defmodule FigKiwi.Schema.TransitionOverride do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:id, 1, type: FigKiwi.Schema.GUID, source_name: "id")
  field(:duration, 2, type: :float, source_name: "duration")
  field(:duration_var, 3, type: FigKiwi.Schema.VariableData, source_name: "durationVar")
  field(:delay, 4, type: :float, source_name: "delay")
  field(:delay_var, 5, type: FigKiwi.Schema.VariableData, source_name: "delayVar")
  field(:easing, 6, type: FigKiwi.Schema.EasingData, source_name: "easing")
  field(:easing_var, 7, type: FigKiwi.Schema.VariableData, source_name: "easingVar")
  field(:created_at_ms, 8, type: :uint64, source_name: "createdAtMs")

  field(:interaction_i_ds, 9,
    repeated: true,
    type: FigKiwi.Schema.GUID,
    source_name: "interactionIDs"
  )

  field(:disabled, 10, type: :bool, source_name: "disabled")
end
