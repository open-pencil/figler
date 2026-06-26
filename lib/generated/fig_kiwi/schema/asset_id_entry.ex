defmodule FigKiwi.Schema.AssetIdEntry do
  @moduledoc "Generated Kiwi message module for `AssetIdEntry`."
  use KiwiCodec, kind: :message
  field(:asset_key, 1, type: :string, source_name: "assetKey")
  field(:asset_id, 2, type: FigKiwi.Schema.AssetId, source_name: "assetId")
end
