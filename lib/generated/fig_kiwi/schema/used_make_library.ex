defmodule FigKiwi.Schema.UsedMakeLibrary do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:make_library_id, 1, type: :string, source_name: "makeLibraryId")
end
