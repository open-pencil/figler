defmodule FigKiwi.Schema.AssetId do
  @moduledoc "Generated Kiwi message module for `AssetId`."
  use KiwiCodec, kind: :message
  field(:guid, 1, type: FigKiwi.Schema.GUID, source_name: "guid")
  field(:asset_ref, 2, type: FigKiwi.Schema.AssetRef, source_name: "assetRef")
  field(:state_group_id, 3, type: FigKiwi.Schema.StateGroupId, source_name: "stateGroupId")
  field(:style_id, 4, type: FigKiwi.Schema.StyleId, source_name: "styleId")
  field(:symbol_id, 5, type: FigKiwi.Schema.SymbolId, source_name: "symbolId")
  field(:variable_id, 6, type: FigKiwi.Schema.VariableID, source_name: "variableId")
  field(:variable_set_id, 7, type: FigKiwi.Schema.VariableSetID, source_name: "variableSetId")
end
