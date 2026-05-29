defmodule FigKiwi.Schema.ChatMessage do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:text, 1, type: :string, source_name: "text")
  field(:previous_text, 2, type: :string, source_name: "previousText")
end
