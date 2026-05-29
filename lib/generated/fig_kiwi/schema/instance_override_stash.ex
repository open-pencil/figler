defmodule FigKiwi.Schema.InstanceOverrideStash do
  @moduledoc false
  use KiwiCodec, kind: :message

  field(:override_path_of_swapped_instance, 1,
    type: FigKiwi.Schema.GUIDPath,
    source_name: "overridePathOfSwappedInstance"
  )

  field(:component_key, 2, type: :string, source_name: "componentKey")
  field(:overrides, 3, repeated: true, type: FigKiwi.Schema.NodeChange, source_name: "overrides")
end
