defmodule Figler.Schema.GridTrackSize do
  @moduledoc "Generated Kiwi message module for `GridTrackSize`."
  use KiwiCodec, kind: :message
  field(:min_sizing, 1, type: Figler.Schema.GridTrackSizingFunction, source_name: "minSizing")
  field(:max_sizing, 2, type: Figler.Schema.GridTrackSizingFunction, source_name: "maxSizing")
end
