defmodule FigKiwi.Schema.CanvasNodeId do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:guid, 1, type: FigKiwi.Schema.GUID, source_name: "guid")
  field(:symbol_id, 2, type: FigKiwi.Schema.SymbolId, source_name: "symbolId")
  field(:state_group_id, 3, type: FigKiwi.Schema.StateGroupId, source_name: "stateGroupId")
end
