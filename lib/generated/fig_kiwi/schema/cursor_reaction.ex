defmodule FigKiwi.Schema.CursorReaction do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:image_url, 1, type: :string, source_name: "imageUrl")
end
