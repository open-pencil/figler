defmodule Figler.Schema.TextCursor do
  @moduledoc "Generated Kiwi message module for `TextCursor`."
  use KiwiCodec, kind: :message
  field(:selection_box, 1, type: Figler.Schema.Rect, source_name: "selectionBox")
  field(:canvas_guid, 2, type: Figler.Schema.GUID, source_name: "canvasGuid")
  field(:text_node_guid, 3, type: Figler.Schema.GUID, source_name: "textNodeGuid")
end
