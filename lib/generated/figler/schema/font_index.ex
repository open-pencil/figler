defmodule Figler.Schema.FontIndex do
  @moduledoc "Generated Kiwi message module for `FontIndex`."
  use KiwiCodec, kind: :message
  field(:schema_version, 1, type: :uint, source_name: "schemaVersion")
  field(:files, 2, repeated: true, type: Figler.Schema.IndexFontFile, source_name: "files")
  field(:renames, 3, type: Figler.Schema.IndexRenames, source_name: "renames")
  field(:emojis, 4, type: Figler.Schema.IndexEmojis, source_name: "emojis")
end
