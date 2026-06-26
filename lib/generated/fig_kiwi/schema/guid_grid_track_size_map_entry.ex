defmodule FigKiwi.Schema.GUIDGridTrackSizeMapEntry do
  @moduledoc "Generated Kiwi message module for `GUIDGridTrackSizeMapEntry`."
  use KiwiCodec, kind: :message
  field(:id, 1, type: FigKiwi.Schema.GUID, source_name: "id")
  field(:track_size, 2, type: FigKiwi.Schema.GridTrackSize, source_name: "trackSize")
end
