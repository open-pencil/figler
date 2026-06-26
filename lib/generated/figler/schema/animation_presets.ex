defmodule Figler.Schema.AnimationPresets do
  @moduledoc "Generated Kiwi message module for `AnimationPresets`."
  use KiwiCodec, kind: :message

  field(:presets, 1,
    repeated: true,
    type: Figler.Schema.AnimationPresetData,
    source_name: "presets"
  )
end
