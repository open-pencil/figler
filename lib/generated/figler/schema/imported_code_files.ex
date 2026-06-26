defmodule Figler.Schema.ImportedCodeFiles do
  @moduledoc "Generated Kiwi message module for `ImportedCodeFiles`."
  use KiwiCodec, kind: :message

  field(:entries, 1,
    repeated: true,
    type: Figler.Schema.ImportedCodeFileEntry,
    source_name: "entries"
  )
end
