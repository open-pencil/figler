defmodule FigKiwi.Schema.GUIDGridTrackSizeMap do
  @moduledoc false
  use KiwiCodec, kind: :message

  field(:entries, 1,
    repeated: true,
    type: FigKiwi.Schema.GUIDGridTrackSizeMapEntry,
    source_name: "entries"
  )
end
