defmodule FigKiwi.Schema.ARIAAttributesMap do
  @moduledoc false
  use KiwiCodec, kind: :message

  field(:entries, 1,
    repeated: true,
    type: FigKiwi.Schema.ARIAAttributesMapEntry,
    source_name: "entries"
  )
end
