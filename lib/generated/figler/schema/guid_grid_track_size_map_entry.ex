defmodule Figler.Schema.GUIDGridTrackSizeMapEntry do
  @moduledoc "Generated Kiwi message module for `GUIDGridTrackSizeMapEntry`."
  use KiwiCodec, kind: :message
  field(:id, 1, type: Figler.Schema.GUID, source_name: "id")
  field(:track_size, 2, type: Figler.Schema.GridTrackSize, source_name: "trackSize")
end
