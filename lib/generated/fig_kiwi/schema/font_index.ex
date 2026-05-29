defmodule FigKiwi.Schema.FontIndex do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:schema_version, 1, type: :uint, source_name: "schemaVersion")
  field(:files, 2, repeated: true, type: FigKiwi.Schema.IndexFontFile, source_name: "files")
  field(:renames, 3, type: FigKiwi.Schema.IndexRenames, source_name: "renames")
  field(:emojis, 4, type: FigKiwi.Schema.IndexEmojis, source_name: "emojis")
end
