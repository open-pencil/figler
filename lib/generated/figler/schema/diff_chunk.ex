defmodule Figler.Schema.DiffChunk do
  @moduledoc "Generated Kiwi message module for `DiffChunk`."
  use KiwiCodec, kind: :message
  field(:node_changes, 1, repeated: true, type: :uint, source_name: "nodeChanges")
  field(:phase, 2, type: {:enum, Figler.Schema.NodePhase}, source_name: "phase")
  field(:display_node, 3, type: Figler.Schema.NodeChange, source_name: "displayNode")
  field(:canvas_id, 4, type: Figler.Schema.GUID, source_name: "canvasId")
  field(:canvas_name, 5, type: :string, source_name: "canvasName")
  field(:canvas_is_internal, 6, type: :bool, source_name: "canvasIsInternal")

  field(:chunks_affecting_this_chunk, 7,
    repeated: true,
    type: :uint,
    source_name: "chunksAffectingThisChunk"
  )

  field(:basis_parent_hierarchy, 8,
    repeated: true,
    type: Figler.Schema.NodeChange,
    source_name: "basisParentHierarchy"
  )

  field(:parent_hierarchy, 9,
    repeated: true,
    type: Figler.Schema.NodeChange,
    source_name: "parentHierarchy"
  )

  field(:basis_parent_hierarchy_guids, 10,
    repeated: true,
    type: Figler.Schema.GUID,
    source_name: "basisParentHierarchyGuids"
  )

  field(:parent_hierarchy_guids, 11,
    repeated: true,
    type: Figler.Schema.GUID,
    source_name: "parentHierarchyGuids"
  )
end
