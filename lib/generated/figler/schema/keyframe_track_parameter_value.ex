defmodule Figler.Schema.KeyframeTrackParameterValue do
  @moduledoc "Generated Kiwi message module for `KeyframeTrackParameterValue`."
  use KiwiCodec, kind: :message

  field(:parameters, 1,
    repeated: true,
    type: Figler.Schema.KeyframeTrackParameter,
    source_name: "parameters"
  )
end
