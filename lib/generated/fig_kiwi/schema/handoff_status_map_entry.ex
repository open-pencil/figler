defmodule FigKiwi.Schema.HandoffStatusMapEntry do
  @moduledoc "Generated Kiwi message module for `HandoffStatusMapEntry`."
  use KiwiCodec, kind: :message
  field(:guid, 1, type: FigKiwi.Schema.GUID, source_name: "guid")
  field(:handoff_status, 2, type: FigKiwi.Schema.SectionStatusInfo, source_name: "handoffStatus")
end
