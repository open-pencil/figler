defmodule FigKiwi.Schema.PresentedState do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:base_screen_id, 1, type: FigKiwi.Schema.GUID, source_name: "baseScreenID")

  field(:overlays, 2,
    repeated: true,
    type: FigKiwi.Schema.TriggeredOverlayData,
    source_name: "overlays"
  )
end
