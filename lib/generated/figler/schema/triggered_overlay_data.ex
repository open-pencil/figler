defmodule Figler.Schema.TriggeredOverlayData do
  @moduledoc "Generated Kiwi message module for `TriggeredOverlayData`."
  use KiwiCodec, kind: :message
  field(:overlay_guid, 1, type: Figler.Schema.GUID, source_name: "overlayGuid")
  field(:hotspot_guid, 2, type: Figler.Schema.GUID, source_name: "hotspotGuid")
  field(:swap_guid, 3, type: Figler.Schema.GUID, source_name: "swapGuid")

  field(:prototype_interaction_guid, 4,
    type: Figler.Schema.GUID,
    source_name: "prototypeInteractionGuid"
  )

  field(:hotspot_blueprint_id, 5, type: Figler.Schema.GUIDPath, source_name: "hotspotBlueprintId")
end
