defmodule FigKiwi.Schema.NodeFieldMap do
  @moduledoc false
  use KiwiCodec, kind: :message

  field(:entries, 1,
    repeated: true,
    type: FigKiwi.Schema.NodeFieldMapEntry,
    source_name: "entries"
  )
end
