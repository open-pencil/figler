defmodule FigKiwi.Schema.StyleAnimation do
  @moduledoc "Generated Kiwi message module for `StyleAnimation`."
  use KiwiCodec, kind: :message

  field(:animation_preset_id, 1,
    type: FigKiwi.Schema.AnimationPresetId,
    source_name: "animationPresetId"
  )
end
