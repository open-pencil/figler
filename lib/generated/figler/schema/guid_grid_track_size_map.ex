defmodule Figler.Schema.GUIDGridTrackSizeMap do
  @moduledoc "Generated Kiwi message module for `GUIDGridTrackSizeMap`."
  use KiwiCodec, kind: :message

  field(:entries, 1,
    repeated: true,
    type: Figler.Schema.GUIDGridTrackSizeMapEntry,
    source_name: "entries"
  )
end
