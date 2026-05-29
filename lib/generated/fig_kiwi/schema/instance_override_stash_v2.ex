defmodule FigKiwi.Schema.InstanceOverrideStashV2 do
  @moduledoc false
  use KiwiCodec, kind: :message

  field(:override_path_of_swapped_instance, 1,
    type: FigKiwi.Schema.GUIDPath,
    source_name: "overridePathOfSwappedInstance"
  )

  field(:local_symbol_id, 2, type: FigKiwi.Schema.GUID, source_name: "localSymbolID")
  field(:overrides, 3, repeated: true, type: FigKiwi.Schema.NodeChange, source_name: "overrides")
end
