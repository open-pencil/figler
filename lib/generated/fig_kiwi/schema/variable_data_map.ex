defmodule FigKiwi.Schema.VariableDataMap do
  @moduledoc "Generated Kiwi message module for `VariableDataMap`."
  use KiwiCodec, kind: :message

  field(:entries, 1,
    repeated: true,
    type: FigKiwi.Schema.VariableDataMapEntry,
    source_name: "entries"
  )
end
