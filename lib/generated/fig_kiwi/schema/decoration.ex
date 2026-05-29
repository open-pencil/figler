defmodule FigKiwi.Schema.Decoration do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:rects, 1, repeated: true, type: FigKiwi.Schema.Rect, source_name: "rects")
  field(:style_id, 2, type: :uint, source_name: "styleID")
end
