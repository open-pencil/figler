defmodule FigKiwi.Schema.InstanceStateChange do
  @moduledoc "Generated Kiwi message module for `InstanceStateChange`."
  use KiwiCodec, kind: :message
  field(:state_id, 1, type: FigKiwi.Schema.GUID, source_name: "stateID")
  field(:interaction_id, 2, type: FigKiwi.Schema.GUID, source_name: "interactionID")
  field(:hotspot_stable_path, 3, type: FigKiwi.Schema.GUIDPath, source_name: "hotspotStablePath")

  field(:instance_stable_path, 4,
    type: FigKiwi.Schema.GUIDPath,
    source_name: "instanceStablePath"
  )

  field(:phase, 5, type: {:enum, FigKiwi.Schema.PlaybackChangePhase}, source_name: "phase")
end
