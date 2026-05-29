defmodule FigKiwi.Schema.AnimationPresets do
  @moduledoc false
  use KiwiCodec, kind: :message

  field(:presets, 1,
    repeated: true,
    type: FigKiwi.Schema.AnimationPresetData,
    source_name: "presets"
  )
end
