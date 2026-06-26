defmodule Figler.Schema.AssetId do
  @moduledoc "Generated Kiwi message module for `AssetId`."
  use KiwiCodec, kind: :message
  field(:guid, 1, type: Figler.Schema.GUID, source_name: "guid")
  field(:asset_ref, 2, type: Figler.Schema.AssetRef, source_name: "assetRef")
  field(:state_group_id, 3, type: Figler.Schema.StateGroupId, source_name: "stateGroupId")
  field(:style_id, 4, type: Figler.Schema.StyleId, source_name: "styleId")
  field(:symbol_id, 5, type: Figler.Schema.SymbolId, source_name: "symbolId")
  field(:variable_id, 6, type: Figler.Schema.VariableID, source_name: "variableId")
  field(:variable_set_id, 7, type: Figler.Schema.VariableSetID, source_name: "variableSetId")
end
