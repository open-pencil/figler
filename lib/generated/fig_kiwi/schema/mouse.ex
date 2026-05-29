defmodule FigKiwi.Schema.Mouse do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:cursor, 1, type: {:enum, FigKiwi.Schema.MouseCursor}, source_name: "cursor")

  field(:canvas_space_location, 2,
    type: FigKiwi.Schema.Vector,
    source_name: "canvasSpaceLocation"
  )

  field(:canvas_space_selection_box, 3,
    type: FigKiwi.Schema.Rect,
    source_name: "canvasSpaceSelectionBox"
  )

  field(:canvas_guid, 4, type: FigKiwi.Schema.GUID, source_name: "canvasGuid")
  field(:cursor_hidden_reason, 5, type: :uint, source_name: "cursorHiddenReason")
end
