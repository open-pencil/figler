defmodule FigKiwi.Schema.BuzzApprovalChange do
  @moduledoc false
  use KiwiCodec, kind: :message

  field(:asset_entries, 1,
    repeated: true,
    type: FigKiwi.Schema.BuzzApprovalAssetEntry,
    source_name: "assetEntries"
  )

  field(:canvas_grid_node_id, 2, type: FigKiwi.Schema.GUID, source_name: "canvasGridNodeId")
  field(:request_id, 3, type: :string, source_name: "requestId")
end
