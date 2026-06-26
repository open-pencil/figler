defmodule Figler.Schema.VariableModeBySetMap do
  @moduledoc "Generated Kiwi message module for `VariableModeBySetMap`."
  use KiwiCodec, kind: :message

  field(:entries, 1,
    repeated: true,
    type: Figler.Schema.VariableModeBySetMapEntry,
    source_name: "entries"
  )
end
