defmodule Figler.Schema.VariableDataMap do
  @moduledoc "Generated Kiwi message module for `VariableDataMap`."
  use KiwiCodec, kind: :message

  field(:entries, 1,
    repeated: true,
    type: Figler.Schema.VariableDataMapEntry,
    source_name: "entries"
  )
end
