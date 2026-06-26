defmodule Figler.Schema.PlatformShapePropertyMapEntry do
  @moduledoc "Generated Kiwi message module for `PlatformShapePropertyMapEntry`."
  use KiwiCodec, kind: :message
  field(:property, 1, type: {:enum, Figler.Schema.PlatformShapeProperty}, source_name: "property")
  field(:node_paths, 2, repeated: true, type: Figler.Schema.GUIDPath, source_name: "nodePaths")
end
