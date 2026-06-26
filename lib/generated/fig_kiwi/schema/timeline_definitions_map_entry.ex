defmodule FigKiwi.Schema.TimelineDefinitionsMapEntry do
  @moduledoc "Generated Kiwi message module for `TimelineDefinitionsMapEntry`."
  use KiwiCodec, kind: :message
  field(:id, 1, type: FigKiwi.Schema.GUID, source_name: "id")
  field(:data, 2, type: FigKiwi.Schema.TimelineData, source_name: "data")
end
