defmodule Figler.Schema.Message do
  @moduledoc "Generated Kiwi message module for `Message`."
  use KiwiCodec, kind: :message
  field(:type, 1, type: {:enum, Figler.Schema.MessageType}, source_name: "type")
  field(:session_id, 2, type: :uint, source_name: "sessionID")
  field(:stable_session_id, 42, type: :string, source_name: "stableSessionID")
  field(:ack_id, 3, type: :uint, source_name: "ackID")
  field(:is_retransmission, 37, type: :bool, source_name: "isRetransmission")

  field(:node_changes, 4,
    repeated: true,
    type: Figler.Schema.NodeChange,
    source_name: "nodeChanges"
  )

  field(:user_changes, 5,
    repeated: true,
    type: Figler.Schema.UserChange,
    source_name: "userChanges"
  )

  field(:interactive_slide_element_change, 32,
    type: Figler.Schema.InteractiveSlideElementChange,
    source_name: "interactiveSlideElementChange"
  )

  field(:node_status_change, 36,
    type: Figler.Schema.NodeStatusChange,
    source_name: "nodeStatusChange"
  )

  field(:buzz_approval_change, 44,
    type: Figler.Schema.BuzzApprovalChange,
    source_name: "buzzApprovalChange"
  )

  field(:blobs, 6, repeated: true, type: Figler.Schema.Blob, source_name: "blobs")
  field(:blob_base_index, 30, type: :uint, source_name: "blobBaseIndex")
  field(:signal_name, 7, type: :string, source_name: "signalName")
  field(:access, 8, type: {:enum, Figler.Schema.Access}, source_name: "access")
  field(:style_set_name, 9, type: :string, source_name: "styleSetName")

  field(:style_set_type, 10,
    type: {:enum, Figler.Schema.StyleSetType},
    source_name: "styleSetType"
  )

  field(:style_set_content_type, 11,
    type: {:enum, Figler.Schema.StyleSetContentType},
    source_name: "styleSetContentType"
  )

  field(:paste_id, 12, type: :int, source_name: "pasteID")
  field(:paste_offset, 13, type: Figler.Schema.Vector, source_name: "pasteOffset")
  field(:paste_file_key, 14, type: :string, source_name: "pasteFileKey")
  field(:signal_payload, 15, type: :string, source_name: "signalPayload")

  field(:scene_graph_queries, 16,
    repeated: true,
    type: Figler.Schema.SceneGraphQuery,
    source_name: "sceneGraphQueries"
  )

  field(:node_changes_metadata, 17,
    type: Figler.Schema.NodeChangesMetadata,
    source_name: "nodeChangesMetadata"
  )

  field(:file_version, 18, type: :uint, source_name: "fileVersion")

  field(:paste_is_partially_outside_enclosing_frame, 19,
    type: :bool,
    source_name: "pasteIsPartiallyOutsideEnclosingFrame"
  )

  field(:paste_page_id, 20, type: Figler.Schema.GUID, source_name: "pastePageId")
  field(:is_cut, 21, type: :bool, source_name: "isCut")

  field(:local_undo_stack, 22,
    repeated: true,
    type: Figler.Schema.Message,
    source_name: "localUndoStack"
  )

  field(:local_redo_stack, 23,
    repeated: true,
    type: Figler.Schema.Message,
    source_name: "localRedoStack"
  )

  field(:broadcasts, 24,
    repeated: true,
    type: Figler.Schema.ClientBroadcast,
    source_name: "broadcasts"
  )

  field(:reconnect_sequence_number, 25, type: :uint, source_name: "reconnectSequenceNumber")
  field(:paste_branch_source_file_key, 26, type: :string, source_name: "pasteBranchSourceFileKey")

  field(:paste_editor_type, 27,
    type: {:enum, Figler.Schema.EditorType},
    source_name: "pasteEditorType"
  )

  field(:post_sync_actions, 28, type: :string, source_name: "postSyncActions")

  field(:published_asset_guids, 29,
    repeated: true,
    type: Figler.Schema.GUID,
    source_name: "publishedAssetGuids"
  )

  field(:dirty_from_initial_load, 31, type: :bool, source_name: "dirtyFromInitialLoad")

  field(:clipboard_selection_regions, 33,
    repeated: true,
    type: Figler.Schema.ClipboardSelectionRegion,
    source_name: "clipboardSelectionRegions"
  )

  field(:encoded_offsets_index, 34,
    type: Figler.Schema.EncodedOffsetsIndex,
    source_name: "encodedOffsetsIndex"
  )

  field(:has_repeating_content, 35, type: :bool, source_name: "hasRepeatingContent")
  field(:sent_timestamp, 38, type: :uint64, source_name: "sentTimestamp")

  field(:annotation_categories, 39,
    repeated: true,
    type: Figler.Schema.AnnotationCategory,
    source_name: "annotationCategories"
  )

  field(:client_rendered_metadata, 40,
    type: Figler.Schema.ClientRenderedMetadata,
    source_name: "clientRenderedMetadata"
  )

  field(:paste_asset_type, 41,
    type: {:enum, Figler.Schema.PasteAssetType},
    source_name: "pasteAssetType"
  )

  field(:object_animations, 43,
    type: Figler.Schema.ObjectAnimationList,
    source_name: "objectAnimations"
  )

  field(:scene_graph_query_mode, 45,
    type: {:enum, Figler.Schema.SceneGraphQueryMode},
    source_name: "sceneGraphQueryMode"
  )
end
