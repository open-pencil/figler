defmodule Figler.Schema.Decoration do
  @moduledoc "Generated Kiwi message module for `Decoration`."
  use KiwiCodec, kind: :message
  field(:rects, 1, repeated: true, type: Figler.Schema.Rect, source_name: "rects")
  field(:style_id, 2, type: :uint, source_name: "styleID")
end
