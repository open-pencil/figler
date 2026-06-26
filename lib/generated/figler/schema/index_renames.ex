defmodule Figler.Schema.IndexRenames do
  @moduledoc "Generated Kiwi struct module for `IndexRenames`."
  use KiwiCodec, kind: :struct
  field(:family, 1, repeated: true, type: Figler.Schema.IndexFamilyRename, source_name: "family")

  field(:style, 2,
    repeated: true,
    type: Figler.Schema.IndexFamilyStylesRename,
    source_name: "style"
  )
end
