defmodule Figler.Schema.AgendaTimerInfo do
  @moduledoc "Generated Kiwi message module for `AgendaTimerInfo`."
  use KiwiCodec, kind: :message
  field(:timer_length, 1, type: :uint, source_name: "timerLength")
end
