defmodule Figler.Schema.KeyframeTrackParameter do
  @moduledoc "Generated Kiwi message module for `KeyframeTrackParameter`."
  use KiwiCodec, kind: :message
  field(:value, 1, type: Figler.Schema.KeyframeTrackAnyParameter, source_name: "value")
  field(:type, 2, type: {:enum, Figler.Schema.KeyframeTrackParameterType}, source_name: "type")
end
