defmodule FigKiwi.Schema.VariableModeBySetMap do
  @moduledoc "Generated Kiwi message module for `VariableModeBySetMap`."
  use KiwiCodec, kind: :message

  field(:entries, 1,
    repeated: true,
    type: FigKiwi.Schema.VariableModeBySetMapEntry,
    source_name: "entries"
  )
end
