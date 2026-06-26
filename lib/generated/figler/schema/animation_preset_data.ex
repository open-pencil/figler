defmodule Figler.Schema.AnimationPresetData do
  @moduledoc "Generated Kiwi message module for `AnimationPresetData`."
  use KiwiCodec, kind: :message

  field(:animation_preset_id, 1,
    type: Figler.Schema.AnimationPresetId,
    source_name: "animationPresetId"
  )

  field(:timeline_def_id, 2, type: Figler.Schema.GUID, source_name: "timelineDefId")
end
