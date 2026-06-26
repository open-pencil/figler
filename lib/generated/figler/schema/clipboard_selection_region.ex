defmodule Figler.Schema.ClipboardSelectionRegion do
  @moduledoc "Generated Kiwi message module for `ClipboardSelectionRegion`."
  use KiwiCodec, kind: :message
  field(:parent, 1, type: Figler.Schema.GUID, source_name: "parent")
  field(:nodes, 2, repeated: true, type: Figler.Schema.GUID, source_name: "nodes")

  field(:enclosing_frame_offset, 3,
    type: Figler.Schema.Vector,
    source_name: "enclosingFrameOffset"
  )

  field(:paste_is_partially_outside_enclosing_frame, 4,
    type: :bool,
    source_name: "pasteIsPartiallyOutsideEnclosingFrame"
  )

  field(:focus_type, 5,
    type: {:enum, Figler.Schema.SelectionRegionFocusType},
    source_name: "focusType"
  )
end
