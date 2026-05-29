defmodule FigKiwi.Schema.MultiplayerFieldVersion do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:counter, 1, type: :uint, source_name: "counter")
  field(:session_id, 2, type: :uint, source_name: "sessionID")
end
