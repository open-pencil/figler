defmodule FigKiwi.Schema.PlatformShapePropertyMapEntry do
  @moduledoc "Generated Kiwi message module for `PlatformShapePropertyMapEntry`."
  use KiwiCodec, kind: :message

  field(:property, 1,
    type: {:enum, FigKiwi.Schema.PlatformShapeProperty},
    source_name: "property"
  )

  field(:node_paths, 2, repeated: true, type: FigKiwi.Schema.GUIDPath, source_name: "nodePaths")
end
