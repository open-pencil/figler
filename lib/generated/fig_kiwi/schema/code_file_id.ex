defmodule FigKiwi.Schema.CodeFileId do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:guid, 1, type: FigKiwi.Schema.GUID, source_name: "guid")
  field(:asset_ref, 2, type: FigKiwi.Schema.AssetRef, source_name: "assetRef")
end
