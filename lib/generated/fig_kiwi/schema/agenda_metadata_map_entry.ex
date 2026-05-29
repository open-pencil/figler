defmodule FigKiwi.Schema.AgendaMetadataMapEntry do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:id, 1, type: FigKiwi.Schema.GUID, source_name: "id")
  field(:data, 2, type: FigKiwi.Schema.AgendaMetadata, source_name: "data")
end
