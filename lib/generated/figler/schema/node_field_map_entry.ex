defmodule Figler.Schema.NodeFieldMapEntry do
  @moduledoc "Generated Kiwi message module for `NodeFieldMapEntry`."
  use KiwiCodec, kind: :message
  field(:guid, 1, type: Figler.Schema.GUID, source_name: "guid")
  field(:field, 2, type: :uint, source_name: "field")
  field(:last_modified_sequence_number, 3, type: :uint, source_name: "lastModifiedSequenceNumber")
end
