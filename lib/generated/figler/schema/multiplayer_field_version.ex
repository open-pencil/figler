defmodule Figler.Schema.MultiplayerFieldVersion do
  @moduledoc "Generated Kiwi message module for `MultiplayerFieldVersion`."
  use KiwiCodec, kind: :message
  field(:counter, 1, type: :uint, source_name: "counter")
  field(:session_id, 2, type: :uint, source_name: "sessionID")
end
