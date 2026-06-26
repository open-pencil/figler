defmodule Figler.Schema.AgendaMetadataMapEntry do
  @moduledoc "Generated Kiwi message module for `AgendaMetadataMapEntry`."
  use KiwiCodec, kind: :message
  field(:id, 1, type: Figler.Schema.GUID, source_name: "id")
  field(:data, 2, type: Figler.Schema.AgendaMetadata, source_name: "data")
end
