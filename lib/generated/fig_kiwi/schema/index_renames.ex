defmodule FigKiwi.Schema.IndexRenames do
  @moduledoc false
  use KiwiCodec, kind: :struct
  field(:family, 1, repeated: true, type: FigKiwi.Schema.IndexFamilyRename, source_name: "family")

  field(:style, 2,
    repeated: true,
    type: FigKiwi.Schema.IndexFamilyStylesRename,
    source_name: "style"
  )
end
