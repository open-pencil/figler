defmodule Figler.Schema.StyleIdForAnimation do
  @moduledoc "Generated Kiwi message module for `StyleIdForAnimation`."
  use KiwiCodec, kind: :message
  field(:id, 1, type: Figler.Schema.GUID, source_name: "id")
  field(:timeline_def_id, 2, type: Figler.Schema.GUID, source_name: "timelineDefId")
  field(:animation_style_id, 3, type: Figler.Schema.StyleId, source_name: "animationStyleId")
  field(:timeline_offset, 4, type: :int64, source_name: "timelineOffset")
end
