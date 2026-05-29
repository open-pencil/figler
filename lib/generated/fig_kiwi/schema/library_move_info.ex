defmodule FigKiwi.Schema.LibraryMoveInfo do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:old_key, 1, type: :string, source_name: "oldKey")
  field(:paste_file_key, 2, type: :string, source_name: "pasteFileKey")
end
