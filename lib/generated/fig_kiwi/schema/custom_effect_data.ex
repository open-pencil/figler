defmodule FigKiwi.Schema.CustomEffectData do
  @moduledoc "Generated Kiwi message module for `CustomEffectData`."
  use KiwiCodec, kind: :message
  field(:custom_effect_id, 1, type: FigKiwi.Schema.CustomEffectId, source_name: "customEffectId")
end
