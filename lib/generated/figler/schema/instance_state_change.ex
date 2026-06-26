defmodule Figler.Schema.InstanceStateChange do
  @moduledoc "Generated Kiwi message module for `InstanceStateChange`."
  use KiwiCodec, kind: :message
  field(:state_id, 1, type: Figler.Schema.GUID, source_name: "stateID")
  field(:interaction_id, 2, type: Figler.Schema.GUID, source_name: "interactionID")
  field(:hotspot_stable_path, 3, type: Figler.Schema.GUIDPath, source_name: "hotspotStablePath")
  field(:instance_stable_path, 4, type: Figler.Schema.GUIDPath, source_name: "instanceStablePath")
  field(:phase, 5, type: {:enum, Figler.Schema.PlaybackChangePhase}, source_name: "phase")
end
