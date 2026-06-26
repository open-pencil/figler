defmodule Figler.Schema.InstanceOverrideStash do
  @moduledoc "Generated Kiwi message module for `InstanceOverrideStash`."
  use KiwiCodec, kind: :message

  field(:override_path_of_swapped_instance, 1,
    type: Figler.Schema.GUIDPath,
    source_name: "overridePathOfSwappedInstance"
  )

  field(:component_key, 2, type: :string, source_name: "componentKey")
  field(:overrides, 3, repeated: true, type: Figler.Schema.NodeChange, source_name: "overrides")
end
