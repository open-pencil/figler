defmodule Figler.Schema.CustomEffects do
  @moduledoc "Generated Kiwi message module for `CustomEffects`."
  use KiwiCodec, kind: :message

  field(:custom_effects, 1,
    repeated: true,
    type: Figler.Schema.CustomEffectData,
    source_name: "customEffects"
  )
end
