defmodule FigKiwi.Schema.AIChatMessage do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:created_at_ms, 1, type: :uint, source_name: "createdAtMs")
  field(:role, 2, type: {:enum, FigKiwi.Schema.AIChatMessageRole}, source_name: "role")

  field(:content, 3,
    repeated: true,
    type: FigKiwi.Schema.AIChatContentPart,
    source_name: "content"
  )

  field(:client_id, 4, type: :string, source_name: "clientId")
  field(:created_at_ms64, 5, type: :uint64, source_name: "createdAtMs64")
end
