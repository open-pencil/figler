defmodule FigKiwi.Schema.TriggeredOverlayData do
  @moduledoc "Generated Kiwi message module for `TriggeredOverlayData`."
  use KiwiCodec, kind: :message
  field(:overlay_guid, 1, type: FigKiwi.Schema.GUID, source_name: "overlayGuid")
  field(:hotspot_guid, 2, type: FigKiwi.Schema.GUID, source_name: "hotspotGuid")
  field(:swap_guid, 3, type: FigKiwi.Schema.GUID, source_name: "swapGuid")

  field(:prototype_interaction_guid, 4,
    type: FigKiwi.Schema.GUID,
    source_name: "prototypeInteractionGuid"
  )

  field(:hotspot_blueprint_id, 5,
    type: FigKiwi.Schema.GUIDPath,
    source_name: "hotspotBlueprintId"
  )
end
