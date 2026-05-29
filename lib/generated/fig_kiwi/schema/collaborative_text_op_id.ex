defmodule FigKiwi.Schema.CollaborativeTextOpID do
  @moduledoc false
  use KiwiCodec, kind: :struct
  field(:session_id, 1, type: :uint, source_name: "sessionID")
  field(:counter_id, 2, type: :uint, source_name: "counterID")
end
