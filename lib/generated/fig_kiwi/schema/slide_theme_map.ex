defmodule FigKiwi.Schema.SlideThemeMap do
  @moduledoc false
  use KiwiCodec, kind: :message

  field(:entries, 1,
    repeated: true,
    type: FigKiwi.Schema.SlideThemeMapEntry,
    source_name: "entries"
  )
end
