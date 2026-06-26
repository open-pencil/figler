defmodule Figler.Schema.VariableDataValues do
  @moduledoc "Generated Kiwi message module for `VariableDataValues`."
  use KiwiCodec, kind: :message

  field(:entries, 1,
    repeated: true,
    type: Figler.Schema.VariableDataValuesEntry,
    source_name: "entries"
  )
end
