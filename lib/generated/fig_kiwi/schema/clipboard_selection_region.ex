defmodule FigKiwi.Schema.ClipboardSelectionRegion do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:parent, 1, type: FigKiwi.Schema.GUID, source_name: "parent")
  field(:nodes, 2, repeated: true, type: FigKiwi.Schema.GUID, source_name: "nodes")

  field(:enclosing_frame_offset, 3,
    type: FigKiwi.Schema.Vector,
    source_name: "enclosingFrameOffset"
  )

  field(:paste_is_partially_outside_enclosing_frame, 4,
    type: :bool,
    source_name: "pasteIsPartiallyOutsideEnclosingFrame"
  )

  field(:focus_type, 5,
    type: {:enum, FigKiwi.Schema.SelectionRegionFocusType},
    source_name: "focusType"
  )
end
