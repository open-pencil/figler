defmodule Figler.Schema.AIChatContentPartAnyValue do
  @moduledoc "Generated Kiwi message module for `AIChatContentPartAnyValue`."
  use KiwiCodec, kind: :message
  field(:text_value, 1, type: :string, source_name: "textValue")
  field(:selected_node_ids, 2, repeated: true, type: :string, source_name: "selectedNodeIds")
end
