defmodule FigKiwi.Schema.AgendaPositionMap do
  @moduledoc "Generated Kiwi message module for `AgendaPositionMap`."
  use KiwiCodec, kind: :message

  field(:entries, 1,
    repeated: true,
    type: FigKiwi.Schema.AgendaPositionMapEntry,
    source_name: "entries"
  )
end
