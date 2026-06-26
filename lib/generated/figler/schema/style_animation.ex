defmodule Figler.Schema.StyleAnimation do
  @moduledoc "Generated Kiwi message module for `StyleAnimation`."
  use KiwiCodec, kind: :message

  field(:animation_preset_id, 1,
    type: Figler.Schema.AnimationPresetId,
    source_name: "animationPresetId"
  )
end
