defmodule Figler.Schema.OverlayBackgroundAppearance do
  @moduledoc "Generated Kiwi message module for `OverlayBackgroundAppearance`."
  use KiwiCodec, kind: :message

  field(:background_type, 1,
    type: {:enum, Figler.Schema.OverlayBackgroundType},
    source_name: "backgroundType"
  )

  field(:background_color, 2, type: Figler.Schema.Color, source_name: "backgroundColor")
end
