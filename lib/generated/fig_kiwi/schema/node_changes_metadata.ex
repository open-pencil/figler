defmodule FigKiwi.Schema.NodeChangesMetadata do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:blobs_field_offset, 1, type: :uint, source_name: "blobsFieldOffset")
end
