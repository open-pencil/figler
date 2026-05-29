defmodule FigKiwi.Schema.GridTrackSizingFunction do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:type, 1, type: {:enum, FigKiwi.Schema.GridTrackSizingType}, source_name: "type")
  field(:value, 2, type: :float, source_name: "value")
end
