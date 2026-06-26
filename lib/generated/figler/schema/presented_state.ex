defmodule Figler.Schema.PresentedState do
  @moduledoc "Generated Kiwi message module for `PresentedState`."
  use KiwiCodec, kind: :message
  field(:base_screen_id, 1, type: Figler.Schema.GUID, source_name: "baseScreenID")

  field(:overlays, 2,
    repeated: true,
    type: Figler.Schema.TriggeredOverlayData,
    source_name: "overlays"
  )
end
