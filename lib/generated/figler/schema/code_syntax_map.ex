defmodule Figler.Schema.CodeSyntaxMap do
  @moduledoc "Generated Kiwi message module for `CodeSyntaxMap`."
  use KiwiCodec, kind: :message

  field(:entries, 1,
    repeated: true,
    type: Figler.Schema.CodeSyntaxMapEntry,
    source_name: "entries"
  )
end
