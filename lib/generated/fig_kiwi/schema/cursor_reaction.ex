defmodule FigKiwi.Schema.CursorReaction do
  @moduledoc "Generated Kiwi message module for `CursorReaction`."
  use KiwiCodec, kind: :message
  field(:image_url, 1, type: :string, source_name: "imageUrl")
end
