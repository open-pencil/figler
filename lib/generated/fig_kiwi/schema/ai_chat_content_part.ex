defmodule FigKiwi.Schema.AIChatContentPart do
  @moduledoc "Generated Kiwi message module for `AIChatContentPart`."
  use KiwiCodec, kind: :message
  field(:type, 1, type: {:enum, FigKiwi.Schema.AIChatContentPartType}, source_name: "type")
  field(:value, 2, type: FigKiwi.Schema.AIChatContentPartAnyValue, source_name: "value")
end
