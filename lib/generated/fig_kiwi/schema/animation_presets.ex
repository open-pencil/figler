defmodule FigKiwi.Schema.AnimationPresets do
  @moduledoc "Generated Kiwi message module for `AnimationPresets`."
  use KiwiCodec, kind: :message

  field(:presets, 1,
    repeated: true,
    type: FigKiwi.Schema.AnimationPresetData,
    source_name: "presets"
  )
end
