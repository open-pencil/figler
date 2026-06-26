defmodule FigKiwi.Schema.DiffPayload do
  @moduledoc "Generated Kiwi message module for `DiffPayload`."
  use KiwiCodec, kind: :message

  field(:node_changes, 1,
    repeated: true,
    type: FigKiwi.Schema.NodeChange,
    source_name: "nodeChanges"
  )

  field(:blobs, 2, repeated: true, type: FigKiwi.Schema.Blob, source_name: "blobs")

  field(:diff_chunks, 3,
    repeated: true,
    type: FigKiwi.Schema.DiffChunk,
    source_name: "diffChunks"
  )

  field(:diff_basis, 4, repeated: true, type: FigKiwi.Schema.NodeChange, source_name: "diffBasis")

  field(:basis_parent_node_changes, 5,
    repeated: true,
    type: FigKiwi.Schema.NodeChange,
    source_name: "basisParentNodeChanges"
  )

  field(:parent_node_changes, 6,
    repeated: true,
    type: FigKiwi.Schema.NodeChange,
    source_name: "parentNodeChanges"
  )

  field(:diff_type, 7, type: {:enum, FigKiwi.Schema.DiffType}, source_name: "diffType")
end
