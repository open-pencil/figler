defmodule FigKiwi.Schema.KeyframeTrackAnyParameter do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:manual, 1, type: FigKiwi.Schema.ManualKeyframeTrackParameter, source_name: "manual")

  field(:animation_preset, 2,
    type: FigKiwi.Schema.AnimationPresetKeyframeTrackParameter,
    source_name: "animationPreset"
  )

  field(:animation_style_binding_id, 3,
    type: FigKiwi.Schema.GUID,
    source_name: "animationStyleBindingId"
  )
end
