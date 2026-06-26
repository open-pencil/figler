defmodule Figler.Schema.ThumbnailInfo do
  @moduledoc "Generated Kiwi message module for `ThumbnailInfo`."
  use KiwiCodec, kind: :message
  field(:node_id, 1, type: Figler.Schema.GUID, source_name: "nodeID")
  field(:thumbnail_version, 2, type: :string, source_name: "thumbnailVersion")
end
