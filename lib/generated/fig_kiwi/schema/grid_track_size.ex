defmodule FigKiwi.Schema.GridTrackSize do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:min_sizing, 1, type: FigKiwi.Schema.GridTrackSizingFunction, source_name: "minSizing")
  field(:max_sizing, 2, type: FigKiwi.Schema.GridTrackSizingFunction, source_name: "maxSizing")
end
