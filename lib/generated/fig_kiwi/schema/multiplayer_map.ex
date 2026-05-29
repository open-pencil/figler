defmodule FigKiwi.Schema.MultiplayerMap do
  @moduledoc false
  use KiwiCodec, kind: :message

  field(:entries, 1,
    repeated: true,
    type: FigKiwi.Schema.MultiplayerMapEntry,
    source_name: "entries"
  )
end
