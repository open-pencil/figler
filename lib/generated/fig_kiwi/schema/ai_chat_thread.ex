defmodule FigKiwi.Schema.AIChatThread do
  @moduledoc "Generated Kiwi message module for `AIChatThread`."
  use KiwiCodec, kind: :message
  field(:messages, 1, repeated: true, type: FigKiwi.Schema.AIChatMessage, source_name: "messages")
end
