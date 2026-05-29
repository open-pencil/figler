defmodule FigKiwi.Schema.AssetIdMap do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:entries, 1, repeated: true, type: FigKiwi.Schema.AssetIdEntry, source_name: "entries")
end
