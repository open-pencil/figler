defmodule FigKiwi.Schema.ARIAAttributesMap do
  @moduledoc "Generated Kiwi message module for `ARIAAttributesMap`."
  use KiwiCodec, kind: :message

  field(:entries, 1,
    repeated: true,
    type: FigKiwi.Schema.ARIAAttributesMapEntry,
    source_name: "entries"
  )
end
