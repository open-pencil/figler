defmodule FigKiwi.Schema.VariableModeBySetMap do
  @moduledoc false
  use KiwiCodec, kind: :message

  field(:entries, 1,
    repeated: true,
    type: FigKiwi.Schema.VariableModeBySetMapEntry,
    source_name: "entries"
  )
end
