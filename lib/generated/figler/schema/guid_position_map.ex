defmodule Figler.Schema.GUIDPositionMap do
  @moduledoc "Generated Kiwi message module for `GUIDPositionMap`."
  use KiwiCodec, kind: :message

  field(:entries, 1,
    repeated: true,
    type: Figler.Schema.GUIDPositionMapEntry,
    source_name: "entries"
  )
end
