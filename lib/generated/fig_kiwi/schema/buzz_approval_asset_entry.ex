defmodule FigKiwi.Schema.BuzzApprovalAssetEntry do
  @moduledoc "Generated Kiwi message module for `BuzzApprovalAssetEntry`."
  use KiwiCodec, kind: :message
  field(:asset_node_id, 1, type: FigKiwi.Schema.GUID, source_name: "assetNodeId")
  field(:approved, 2, type: :bool, source_name: "approved")
end
