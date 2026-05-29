defmodule FigKiwi.Schema.StyleAnimation do
  @moduledoc false
  use KiwiCodec, kind: :message

  field(:animation_preset_id, 1,
    type: FigKiwi.Schema.AnimationPresetId,
    source_name: "animationPresetId"
  )
end
