defmodule FigKiwi.Schema.NodeFieldMap do
  @moduledoc "Generated Kiwi message module for `NodeFieldMap`."
  use KiwiCodec, kind: :message

  field(:entries, 1,
    repeated: true,
    type: FigKiwi.Schema.NodeFieldMapEntry,
    source_name: "entries"
  )
end
