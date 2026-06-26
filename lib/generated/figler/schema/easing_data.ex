defmodule Figler.Schema.EasingData do
  @moduledoc "Generated Kiwi message module for `EasingData`."
  use KiwiCodec, kind: :message
  field(:easing_type, 1, type: {:enum, Figler.Schema.EasingType}, source_name: "easingType")

  field(:easing_value, 2,
    type: Figler.Schema.TransitionEasingAnyValue,
    source_name: "easingValue"
  )
end
