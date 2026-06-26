defmodule FigKiwi.Schema.GUIDPositionMap do
  @moduledoc "Generated Kiwi message module for `GUIDPositionMap`."
  use KiwiCodec, kind: :message

  field(:entries, 1,
    repeated: true,
    type: FigKiwi.Schema.GUIDPositionMapEntry,
    source_name: "entries"
  )
end
