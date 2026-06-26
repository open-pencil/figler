defmodule Figler.Schema.CanvasNodeId do
  @moduledoc "Generated Kiwi message module for `CanvasNodeId`."
  use KiwiCodec, kind: :message
  field(:guid, 1, type: Figler.Schema.GUID, source_name: "guid")
  field(:symbol_id, 2, type: Figler.Schema.SymbolId, source_name: "symbolId")
  field(:state_group_id, 3, type: Figler.Schema.StateGroupId, source_name: "stateGroupId")
end
