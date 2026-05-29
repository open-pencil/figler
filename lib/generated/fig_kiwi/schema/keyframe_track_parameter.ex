defmodule FigKiwi.Schema.KeyframeTrackParameter do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:value, 1, type: FigKiwi.Schema.KeyframeTrackAnyParameter, source_name: "value")
  field(:type, 2, type: {:enum, FigKiwi.Schema.KeyframeTrackParameterType}, source_name: "type")
end
