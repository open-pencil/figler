defmodule Figler.Schema.TransitionInfo do
  @moduledoc "Generated Kiwi message module for `TransitionInfo`."
  use KiwiCodec, kind: :message
  field(:type, 1, type: {:enum, Figler.Schema.TransitionType}, source_name: "type")
  field(:duration, 2, type: :float, source_name: "duration")
end
