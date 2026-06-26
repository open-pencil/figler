defmodule FigKiwi.Schema.MentionBox do
  @moduledoc "Generated Kiwi message module for `MentionBox`."
  use KiwiCodec, kind: :message
  field(:bounds, 1, type: FigKiwi.Schema.Rect, source_name: "bounds")
  field(:start_index, 2, type: :uint, source_name: "startIndex")
  field(:end_index, 3, type: :uint, source_name: "endIndex")
  field(:is_valid, 4, type: :bool, source_name: "isValid")
  field(:mention_key, 5, type: :uint, source_name: "mentionKey")
end
