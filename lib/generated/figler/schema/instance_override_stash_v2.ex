defmodule Figler.Schema.InstanceOverrideStashV2 do
  @moduledoc "Generated Kiwi message module for `InstanceOverrideStashV2`."
  use KiwiCodec, kind: :message

  field(:override_path_of_swapped_instance, 1,
    type: Figler.Schema.GUIDPath,
    source_name: "overridePathOfSwappedInstance"
  )

  field(:local_symbol_id, 2, type: Figler.Schema.GUID, source_name: "localSymbolID")
  field(:overrides, 3, repeated: true, type: Figler.Schema.NodeChange, source_name: "overrides")
end
