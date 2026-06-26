defmodule FigKiwi.Schema.TopLevelPlaybackChange do
  @moduledoc "Generated Kiwi message module for `TopLevelPlaybackChange`."
  use KiwiCodec, kind: :message
  field(:old_state, 1, type: FigKiwi.Schema.PresentedState, source_name: "oldState")
  field(:new_state, 2, type: FigKiwi.Schema.PresentedState, source_name: "newState")

  field(:hotspot_blueprint_id, 3,
    type: FigKiwi.Schema.GUIDPath,
    source_name: "hotspotBlueprintID"
  )

  field(:interaction_id, 4, type: FigKiwi.Schema.GUID, source_name: "interactionID")

  field(:is_hotspot_in_new_presented_state, 5,
    type: :bool,
    source_name: "isHotspotInNewPresentedState"
  )

  field(:direction, 6,
    type: {:enum, FigKiwi.Schema.TransitionDirection},
    source_name: "direction"
  )

  field(:instance_stable_path, 7,
    type: FigKiwi.Schema.GUIDPath,
    source_name: "instanceStablePath"
  )
end
