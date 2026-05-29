defmodule FigKiwi.Schema.PlatformShapeDefinition do
  @moduledoc false
  use KiwiCodec, kind: :message

  field(:property_map_entries, 1,
    repeated: true,
    type: FigKiwi.Schema.PlatformShapePropertyMapEntry,
    source_name: "propertyMapEntries"
  )

  field(:behavior_type, 2,
    type: {:enum, FigKiwi.Schema.PlatformShapeBehaviorType},
    source_name: "behaviorType"
  )

  field(:thumbnail_node, 3, type: FigKiwi.Schema.GUIDPath, source_name: "thumbnailNode")
end
