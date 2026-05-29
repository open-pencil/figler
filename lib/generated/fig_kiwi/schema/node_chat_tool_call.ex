defmodule FigKiwi.Schema.NodeChatToolCall do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:tool_call_id, 1, type: :string, source_name: "toolCallId")
  field(:tool_name, 2, type: :string, source_name: "toolName")
  field(:args_json, 3, type: :string, source_name: "argsJson")
end
