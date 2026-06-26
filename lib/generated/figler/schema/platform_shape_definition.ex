defmodule Figler.Schema.PlatformShapeDefinition do
  @moduledoc "Generated Kiwi message module for `PlatformShapeDefinition`."
  use KiwiCodec, kind: :message

  field(:property_map_entries, 1,
    repeated: true,
    type: Figler.Schema.PlatformShapePropertyMapEntry,
    source_name: "propertyMapEntries"
  )

  field(:behavior_type, 2,
    type: {:enum, Figler.Schema.PlatformShapeBehaviorType},
    source_name: "behaviorType"
  )

  field(:thumbnail_node, 3, type: Figler.Schema.GUIDPath, source_name: "thumbnailNode")
end
