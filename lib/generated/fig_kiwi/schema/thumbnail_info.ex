defmodule FigKiwi.Schema.ThumbnailInfo do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:node_id, 1, type: FigKiwi.Schema.GUID, source_name: "nodeID")
  field(:thumbnail_version, 2, type: :string, source_name: "thumbnailVersion")
end
