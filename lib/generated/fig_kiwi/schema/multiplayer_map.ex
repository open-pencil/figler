defmodule FigKiwi.Schema.MultiplayerMap do
  @moduledoc "Generated Kiwi message module for `MultiplayerMap`."
  use KiwiCodec, kind: :message

  field(:entries, 1,
    repeated: true,
    type: FigKiwi.Schema.MultiplayerMapEntry,
    source_name: "entries"
  )
end
