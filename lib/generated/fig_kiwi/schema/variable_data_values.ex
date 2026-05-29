defmodule FigKiwi.Schema.VariableDataValues do
  @moduledoc false
  use KiwiCodec, kind: :message

  field(:entries, 1,
    repeated: true,
    type: FigKiwi.Schema.VariableDataValuesEntry,
    source_name: "entries"
  )
end
