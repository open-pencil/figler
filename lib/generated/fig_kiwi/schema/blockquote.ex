defmodule FigKiwi.Schema.Blockquote do
  @moduledoc "Generated Kiwi message module for `Blockquote`."
  use KiwiCodec, kind: :message
  field(:vertical_bar, 1, type: FigKiwi.Schema.Rect, source_name: "verticalBar")
  field(:quote_mark_bounds, 2, type: FigKiwi.Schema.Rect, source_name: "quoteMarkBounds")
  field(:style_id, 3, type: :uint, source_name: "styleID")
end
