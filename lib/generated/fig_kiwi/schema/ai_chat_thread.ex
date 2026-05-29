defmodule FigKiwi.Schema.AIChatThread do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:messages, 1, repeated: true, type: FigKiwi.Schema.AIChatMessage, source_name: "messages")
end
