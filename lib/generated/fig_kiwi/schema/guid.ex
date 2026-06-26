defmodule FigKiwi.Schema.GUID do
  @moduledoc "Generated Kiwi struct module for `GUID`."
  use KiwiCodec, kind: :struct
  field(:session_id, 1, type: :uint, source_name: "sessionID")
  field(:local_id, 2, type: :uint, source_name: "localID")
end
