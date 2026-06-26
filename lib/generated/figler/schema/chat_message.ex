defmodule Figler.Schema.ChatMessage do
  @moduledoc "Generated Kiwi message module for `ChatMessage`."
  use KiwiCodec, kind: :message
  field(:text, 1, type: :string, source_name: "text")
  field(:previous_text, 2, type: :string, source_name: "previousText")
end
