defmodule FigKiwi.Schema.UsedMakeLibrary do
  @moduledoc "Generated Kiwi message module for `UsedMakeLibrary`."
  use KiwiCodec, kind: :message
  field(:make_library_id, 1, type: :string, source_name: "makeLibraryId")
end
