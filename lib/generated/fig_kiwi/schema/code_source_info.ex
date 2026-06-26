defmodule FigKiwi.Schema.CodeSourceInfo do
  @moduledoc "Generated Kiwi message module for `CodeSourceInfo`."
  use KiwiCodec, kind: :message
  field(:origin_reference_id, 1, type: :string, source_name: "originReferenceId")
  field(:origin_node_id, 2, type: FigKiwi.Schema.GUID, source_name: "originNodeId")
  field(:linked_snapshot_id, 3, type: FigKiwi.Schema.GUID, source_name: "linkedSnapshotId")

  field(:capture_mode, 4,
    type: {:enum, FigKiwi.Schema.SnapshotCaptureMode},
    source_name: "captureMode"
  )

  field(:source_blob_ref, 5, type: :string, source_name: "sourceBlobRef")
  field(:source_element_id, 6, type: :string, source_name: "sourceElementId")
end
