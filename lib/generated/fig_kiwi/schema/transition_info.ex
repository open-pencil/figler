defmodule FigKiwi.Schema.TransitionInfo do
  @moduledoc "Generated Kiwi message module for `TransitionInfo`."
  use KiwiCodec, kind: :message
  field(:type, 1, type: {:enum, FigKiwi.Schema.TransitionType}, source_name: "type")
  field(:duration, 2, type: :float, source_name: "duration")
end
