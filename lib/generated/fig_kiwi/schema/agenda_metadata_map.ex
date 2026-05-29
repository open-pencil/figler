defmodule FigKiwi.Schema.AgendaMetadataMap do
  @moduledoc false
  use KiwiCodec, kind: :message

  field(:entries, 1,
    repeated: true,
    type: FigKiwi.Schema.AgendaMetadataMapEntry,
    source_name: "entries"
  )
end
