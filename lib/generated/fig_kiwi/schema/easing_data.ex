defmodule FigKiwi.Schema.EasingData do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:easing_type, 1, type: {:enum, FigKiwi.Schema.EasingType}, source_name: "easingType")

  field(:easing_value, 2,
    type: FigKiwi.Schema.TransitionEasingAnyValue,
    source_name: "easingValue"
  )
end
