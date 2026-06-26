defmodule FigKiwi.Schema.ImportedCodeFiles do
  @moduledoc "Generated Kiwi message module for `ImportedCodeFiles`."
  use KiwiCodec, kind: :message

  field(:entries, 1,
    repeated: true,
    type: FigKiwi.Schema.ImportedCodeFileEntry,
    source_name: "entries"
  )
end
