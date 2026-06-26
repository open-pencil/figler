defmodule Figler.Schema.AgendaMetadataMap do
  @moduledoc "Generated Kiwi message module for `AgendaMetadataMap`."
  use KiwiCodec, kind: :message

  field(:entries, 1,
    repeated: true,
    type: Figler.Schema.AgendaMetadataMapEntry,
    source_name: "entries"
  )
end
