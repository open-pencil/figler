defmodule FigKiwi.Schema.TextSelection do
  @moduledoc "Generated Kiwi message module for `TextSelection`."
  use KiwiCodec, kind: :message

  field(:selection_boxes, 1,
    repeated: true,
    type: FigKiwi.Schema.Rect,
    source_name: "selectionBoxes"
  )

  field(:canvas_guid, 2, type: FigKiwi.Schema.GUID, source_name: "canvasGuid")
  field(:text_node_guid, 3, type: FigKiwi.Schema.GUID, source_name: "textNodeGuid")
  field(:text_selection_range, 4, type: FigKiwi.Schema.Vector, source_name: "textSelectionRange")

  field(:text_node_or_containing_if_guid, 5,
    type: FigKiwi.Schema.GUID,
    source_name: "textNodeOrContainingIfGuid"
  )

  field(:table_cell_row_id, 6, type: FigKiwi.Schema.GUID, source_name: "tableCellRowId")
  field(:table_cell_col_id, 7, type: FigKiwi.Schema.GUID, source_name: "tableCellColId")
end
