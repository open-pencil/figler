defmodule Figler.Schema.CursorBehavior do
  @moduledoc "Generated Kiwi message module for `CursorBehavior`."
  use KiwiCodec, kind: :message
  field(:hotspot_x, 1, type: :float, source_name: "hotspotX")
  field(:hotspot_y, 2, type: :float, source_name: "hotspotY")
  field(:cursor_guid, 3, type: Figler.Schema.GUID, source_name: "cursorGuid")
  field(:is_deleted, 4, type: :bool, source_name: "isDeleted")
end
