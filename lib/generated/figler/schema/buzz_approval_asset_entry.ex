defmodule Figler.Schema.BuzzApprovalAssetEntry do
  @moduledoc "Generated Kiwi message module for `BuzzApprovalAssetEntry`."
  use KiwiCodec, kind: :message
  field(:asset_node_id, 1, type: Figler.Schema.GUID, source_name: "assetNodeId")
  field(:approved, 2, type: :bool, source_name: "approved")
end
