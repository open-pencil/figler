defmodule FigKiwi.Schema.CodeSyntaxMap do
  @moduledoc false
  use KiwiCodec, kind: :message

  field(:entries, 1,
    repeated: true,
    type: FigKiwi.Schema.CodeSyntaxMapEntry,
    source_name: "entries"
  )
end
