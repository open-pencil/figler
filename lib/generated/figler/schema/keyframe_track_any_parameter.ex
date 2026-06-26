defmodule Figler.Schema.KeyframeTrackAnyParameter do
  @moduledoc "Generated Kiwi message module for `KeyframeTrackAnyParameter`."
  use KiwiCodec, kind: :message
  field(:manual, 1, type: Figler.Schema.ManualKeyframeTrackParameter, source_name: "manual")

  field(:animation_preset, 2,
    type: Figler.Schema.AnimationPresetKeyframeTrackParameter,
    source_name: "animationPreset"
  )

  field(:animation_style_binding_id, 3,
    type: Figler.Schema.GUID,
    source_name: "animationStyleBindingId"
  )
end
