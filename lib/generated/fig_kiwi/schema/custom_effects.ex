defmodule FigKiwi.Schema.CustomEffects do
  @moduledoc "Generated Kiwi message module for `CustomEffects`."
  use KiwiCodec, kind: :message

  field(:custom_effects, 1,
    repeated: true,
    type: FigKiwi.Schema.CustomEffectData,
    source_name: "customEffects"
  )
end
