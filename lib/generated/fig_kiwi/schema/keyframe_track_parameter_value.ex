defmodule FigKiwi.Schema.KeyframeTrackParameterValue do
  @moduledoc "Generated Kiwi message module for `KeyframeTrackParameterValue`."
  use KiwiCodec, kind: :message

  field(:parameters, 1,
    repeated: true,
    type: FigKiwi.Schema.KeyframeTrackParameter,
    source_name: "parameters"
  )
end
