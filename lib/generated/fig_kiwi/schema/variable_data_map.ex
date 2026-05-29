defmodule FigKiwi.Schema.VariableDataMap do
  @moduledoc false
  use KiwiCodec, kind: :message

  field(:entries, 1,
    repeated: true,
    type: FigKiwi.Schema.VariableDataMapEntry,
    source_name: "entries"
  )
end
