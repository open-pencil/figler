defmodule FigKiwi.Schema.OverlayBackgroundAppearance do
  @moduledoc "Generated Kiwi message module for `OverlayBackgroundAppearance`."
  use KiwiCodec, kind: :message

  field(:background_type, 1,
    type: {:enum, FigKiwi.Schema.OverlayBackgroundType},
    source_name: "backgroundType"
  )

  field(:background_color, 2, type: FigKiwi.Schema.Color, source_name: "backgroundColor")
end
