defmodule FigKiwi.Schema.IndexFamilyRename do
  @moduledoc false
  use KiwiCodec, kind: :struct
  field(:old_family, 1, type: :string, source_name: "oldFamily")
  field(:new_family, 2, type: :string, source_name: "newFamily")
end
