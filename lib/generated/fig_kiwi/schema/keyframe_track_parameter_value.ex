defmodule FigKiwi.Schema.KeyframeTrackParameterValue do
  @moduledoc false
  use KiwiCodec, kind: :message

  field(:parameters, 1,
    repeated: true,
    type: FigKiwi.Schema.KeyframeTrackParameter,
    source_name: "parameters"
  )
end
