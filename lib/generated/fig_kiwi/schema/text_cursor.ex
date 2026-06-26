defmodule FigKiwi.Schema.TextCursor do
  @moduledoc "Generated Kiwi message module for `TextCursor`."
  use KiwiCodec, kind: :message
  field(:selection_box, 1, type: FigKiwi.Schema.Rect, source_name: "selectionBox")
  field(:canvas_guid, 2, type: FigKiwi.Schema.GUID, source_name: "canvasGuid")
  field(:text_node_guid, 3, type: FigKiwi.Schema.GUID, source_name: "textNodeGuid")
end
