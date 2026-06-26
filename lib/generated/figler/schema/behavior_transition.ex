defmodule Figler.Schema.BehaviorTransition do
  @moduledoc "Generated Kiwi message module for `BehaviorTransition`."
  use KiwiCodec, kind: :message
  field(:easing_type, 1, type: {:enum, Figler.Schema.EasingType}, source_name: "easingType")
  field(:easing_function, 2, repeated: true, type: :float, source_name: "easingFunction")
  field(:transition_duration, 3, type: :float, source_name: "transitionDuration")
  field(:delay, 4, type: :float, source_name: "delay")

  field(:transition_duration_var, 5,
    type: Figler.Schema.VariableData,
    source_name: "transitionDurationVar"
  )

  field(:delay_var, 6, type: Figler.Schema.VariableData, source_name: "delayVar")
end
