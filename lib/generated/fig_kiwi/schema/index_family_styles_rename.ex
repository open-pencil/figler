defmodule FigKiwi.Schema.IndexFamilyStylesRename do
  @moduledoc false
  use KiwiCodec, kind: :struct
  field(:family_name, 1, type: :string, source_name: "familyName")

  field(:style_renames, 2,
    repeated: true,
    type: FigKiwi.Schema.IndexStyleRename,
    source_name: "styleRenames"
  )
end
