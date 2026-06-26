defmodule FigKiwi.Schema.BuzzApprovalChange do
  @moduledoc "Generated Kiwi message module for `BuzzApprovalChange`."
  use KiwiCodec, kind: :message

  field(:asset_entries, 1,
    repeated: true,
    type: FigKiwi.Schema.BuzzApprovalAssetEntry,
    source_name: "assetEntries"
  )

  field(:canvas_grid_node_id, 2, type: FigKiwi.Schema.GUID, source_name: "canvasGridNodeId")
  field(:request_id, 3, type: :string, source_name: "requestId")
end
