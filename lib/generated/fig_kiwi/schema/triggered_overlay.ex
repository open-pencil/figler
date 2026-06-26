defmodule FigKiwi.Schema.TriggeredOverlay do
  @moduledoc "Generated Kiwi struct module for `TriggeredOverlay`."
  use KiwiCodec, kind: :struct
  field(:overlay_guid, 1, type: FigKiwi.Schema.GUID, source_name: "overlayGuid")
  field(:hotspot_guid, 2, type: FigKiwi.Schema.GUID, source_name: "hotspotGuid")
  field(:swap_guid, 3, type: FigKiwi.Schema.GUID, source_name: "swapGuid")
end
