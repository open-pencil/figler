defmodule Figler.Schema.GridTrackSizingFunction do
  @moduledoc "Generated Kiwi message module for `GridTrackSizingFunction`."
  use KiwiCodec, kind: :message
  field(:type, 1, type: {:enum, Figler.Schema.GridTrackSizingType}, source_name: "type")
  field(:value, 2, type: :float, source_name: "value")
end
