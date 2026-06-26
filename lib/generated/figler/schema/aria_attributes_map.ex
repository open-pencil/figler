defmodule Figler.Schema.ARIAAttributesMap do
  @moduledoc "Generated Kiwi message module for `ARIAAttributesMap`."
  use KiwiCodec, kind: :message

  field(:entries, 1,
    repeated: true,
    type: Figler.Schema.ARIAAttributesMapEntry,
    source_name: "entries"
  )
end
