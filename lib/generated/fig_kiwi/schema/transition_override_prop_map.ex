defmodule FigKiwi.Schema.TransitionOverridePropMap do
  @moduledoc "Generated Kiwi message module for `TransitionOverridePropMap`."
  use KiwiCodec, kind: :message

  field(:entries, 1,
    repeated: true,
    type: FigKiwi.Schema.TransitionOverridePropMapEntry,
    source_name: "entries"
  )
end
