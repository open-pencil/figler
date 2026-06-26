defmodule Figler.Schema.CollaborativeTextOpID do
  @moduledoc "Generated Kiwi struct module for `CollaborativeTextOpID`."
  use KiwiCodec, kind: :struct
  field(:session_id, 1, type: :uint, source_name: "sessionID")
  field(:counter_id, 2, type: :uint, source_name: "counterID")
end
