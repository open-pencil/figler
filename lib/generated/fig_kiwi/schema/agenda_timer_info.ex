defmodule FigKiwi.Schema.AgendaTimerInfo do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:timer_length, 1, type: :uint, source_name: "timerLength")
end
