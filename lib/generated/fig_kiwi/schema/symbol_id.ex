defmodule FigKiwi.Schema.SymbolId do
  @moduledoc "Generated Kiwi message module for `SymbolId`."
  use KiwiCodec, kind: :message
  field(:guid, 1, type: FigKiwi.Schema.GUID, source_name: "guid")
  field(:asset_ref, 2, type: FigKiwi.Schema.AssetRef, source_name: "assetRef")
end
