defmodule FigKiwi.Schema.TransitionInfo do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:type, 1, type: {:enum, FigKiwi.Schema.TransitionType}, source_name: "type")
  field(:duration, 2, type: :float, source_name: "duration")
end
