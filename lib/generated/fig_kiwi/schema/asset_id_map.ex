defmodule FigKiwi.Schema.AssetIdMap do
  @moduledoc "Generated Kiwi message module for `AssetIdMap`."
  use KiwiCodec, kind: :message
  field(:entries, 1, repeated: true, type: FigKiwi.Schema.AssetIdEntry, source_name: "entries")
end
