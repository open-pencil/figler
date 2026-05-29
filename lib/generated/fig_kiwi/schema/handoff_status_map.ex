defmodule FigKiwi.Schema.HandoffStatusMap do
  @moduledoc false
  use KiwiCodec, kind: :message

  field(:entries, 1,
    repeated: true,
    type: FigKiwi.Schema.HandoffStatusMapEntry,
    source_name: "entries"
  )
end
