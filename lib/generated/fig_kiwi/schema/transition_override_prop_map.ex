defmodule FigKiwi.Schema.TransitionOverridePropMap do
  @moduledoc false
  use KiwiCodec, kind: :message

  field(:entries, 1,
    repeated: true,
    type: FigKiwi.Schema.TransitionOverridePropMapEntry,
    source_name: "entries"
  )
end
