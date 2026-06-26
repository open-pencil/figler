defmodule FigKiwi.Schema.CollaborativeTextSelection do
  @moduledoc "Generated Kiwi message module for `CollaborativeTextSelection`."
  use KiwiCodec, kind: :message
  field(:node, 1, type: FigKiwi.Schema.GUID, source_name: "node")
  field(:field, 2, type: :uint, source_name: "field")
  field(:selected_range, 3, type: FigKiwi.Schema.IndexRange, source_name: "selectedRange")
  field(:caret_at_front, 4, type: :bool, source_name: "caretAtFront")

  field(:text_version, 5,
    repeated: true,
    type: FigKiwi.Schema.CollaborativeTextOpID,
    source_name: "textVersion"
  )
end
