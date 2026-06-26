defmodule Figler.Schema.NodeChangesMetadata do
  @moduledoc "Generated Kiwi message module for `NodeChangesMetadata`."
  use KiwiCodec, kind: :message
  field(:blobs_field_offset, 1, type: :uint, source_name: "blobsFieldOffset")
end
