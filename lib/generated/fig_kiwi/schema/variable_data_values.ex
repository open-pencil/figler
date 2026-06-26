defmodule FigKiwi.Schema.VariableDataValues do
  @moduledoc "Generated Kiwi message module for `VariableDataValues`."
  use KiwiCodec, kind: :message

  field(:entries, 1,
    repeated: true,
    type: FigKiwi.Schema.VariableDataValuesEntry,
    source_name: "entries"
  )
end
