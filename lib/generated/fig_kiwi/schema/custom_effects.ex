defmodule FigKiwi.Schema.CustomEffects do
  @moduledoc false
  use KiwiCodec, kind: :message

  field(:custom_effects, 1,
    repeated: true,
    type: FigKiwi.Schema.CustomEffectData,
    source_name: "customEffects"
  )
end
