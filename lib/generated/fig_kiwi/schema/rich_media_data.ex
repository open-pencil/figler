defmodule FigKiwi.Schema.RichMediaData do
  @moduledoc "Generated Kiwi message module for `RichMediaData`."
  use KiwiCodec, kind: :message
  field(:media_hash, 1, type: :string, source_name: "mediaHash")

  field(:rich_media_type, 2,
    type: {:enum, FigKiwi.Schema.RichMediaType},
    source_name: "richMediaType"
  )
end
