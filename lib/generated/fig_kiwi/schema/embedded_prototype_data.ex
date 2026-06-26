defmodule FigKiwi.Schema.EmbeddedPrototypeData do
  @moduledoc "Generated Kiwi message module for `EmbeddedPrototypeData`."
  use KiwiCodec, kind: :message
  field(:node_id, 1, type: FigKiwi.Schema.GUID, source_name: "nodeId")
  field(:session_id, 2, type: :uint, source_name: "sessionId")
end
