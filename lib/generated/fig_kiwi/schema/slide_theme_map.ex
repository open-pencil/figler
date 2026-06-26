defmodule FigKiwi.Schema.SlideThemeMap do
  @moduledoc "Generated Kiwi message module for `SlideThemeMap`."
  use KiwiCodec, kind: :message

  field(:entries, 1,
    repeated: true,
    type: FigKiwi.Schema.SlideThemeMapEntry,
    source_name: "entries"
  )
end
