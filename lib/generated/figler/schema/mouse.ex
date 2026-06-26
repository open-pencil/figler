defmodule Figler.Schema.Mouse do
  @moduledoc "Generated Kiwi message module for `Mouse`."
  use KiwiCodec, kind: :message
  field(:cursor, 1, type: {:enum, Figler.Schema.MouseCursor}, source_name: "cursor")
  field(:canvas_space_location, 2, type: Figler.Schema.Vector, source_name: "canvasSpaceLocation")

  field(:canvas_space_selection_box, 3,
    type: Figler.Schema.Rect,
    source_name: "canvasSpaceSelectionBox"
  )

  field(:canvas_guid, 4, type: Figler.Schema.GUID, source_name: "canvasGuid")
  field(:cursor_hidden_reason, 5, type: :uint, source_name: "cursorHiddenReason")
end
