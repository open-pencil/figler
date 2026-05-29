defmodule FigKiwi.Schema.AIChatContentPartAnyValue do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:text_value, 1, type: :string, source_name: "textValue")
  field(:selected_node_ids, 2, repeated: true, type: :string, source_name: "selectedNodeIds")
end
