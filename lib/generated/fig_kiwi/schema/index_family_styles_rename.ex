defmodule FigKiwi.Schema.IndexFamilyStylesRename do
  @moduledoc "Generated Kiwi struct module for `IndexFamilyStylesRename`."
  use KiwiCodec, kind: :struct
  field(:family_name, 1, type: :string, source_name: "familyName")

  field(:style_renames, 2,
    repeated: true,
    type: FigKiwi.Schema.IndexStyleRename,
    source_name: "styleRenames"
  )
end
