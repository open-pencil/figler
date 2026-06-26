defmodule FigKiwi.Schema.CodeSyntaxMap do
  @moduledoc "Generated Kiwi message module for `CodeSyntaxMap`."
  use KiwiCodec, kind: :message

  field(:entries, 1,
    repeated: true,
    type: FigKiwi.Schema.CodeSyntaxMapEntry,
    source_name: "entries"
  )
end
