defmodule FigKiwi.Schema.AnimationPresetData do
  @moduledoc "Generated Kiwi message module for `AnimationPresetData`."
  use KiwiCodec, kind: :message

  field(:animation_preset_id, 1,
    type: FigKiwi.Schema.AnimationPresetId,
    source_name: "animationPresetId"
  )

  field(:timeline_def_id, 2, type: FigKiwi.Schema.GUID, source_name: "timelineDefId")
end
