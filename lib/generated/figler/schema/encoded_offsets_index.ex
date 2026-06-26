defmodule Figler.Schema.EncodedOffsetsIndex do
  @moduledoc "Generated Kiwi message module for `EncodedOffsetsIndex`."
  use KiwiCodec, kind: :message
  field(:node_changes_field_offset, 1, type: :uint, source_name: "nodeChangesFieldOffset")
  field(:node_changes_field_length, 2, type: :uint, source_name: "nodeChangesFieldLength")
  field(:blobs_field_offset, 3, type: :uint, source_name: "blobsFieldOffset")

  field(:node_change_offsets, 4,
    repeated: true,
    type: Figler.Schema.GUIDAndEncodedOffset,
    source_name: "nodeChangeOffsets"
  )
end
