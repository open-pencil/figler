defmodule FigKiwi.Schema.HandoffStatusMap do
  @moduledoc "Generated Kiwi message module for `HandoffStatusMap`."
  use KiwiCodec, kind: :message

  field(:entries, 1,
    repeated: true,
    type: FigKiwi.Schema.HandoffStatusMapEntry,
    source_name: "entries"
  )
end
