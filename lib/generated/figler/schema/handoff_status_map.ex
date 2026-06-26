defmodule Figler.Schema.HandoffStatusMap do
  @moduledoc "Generated Kiwi message module for `HandoffStatusMap`."
  use KiwiCodec, kind: :message

  field(:entries, 1,
    repeated: true,
    type: Figler.Schema.HandoffStatusMapEntry,
    source_name: "entries"
  )
end
