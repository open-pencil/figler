defmodule Figler.Schema.NodeChatToolResult do
  @moduledoc "Generated Kiwi message module for `NodeChatToolResult`."
  use KiwiCodec, kind: :message
  field(:tool_call_id, 1, type: :string, source_name: "toolCallId")
  field(:tool_name, 2, type: :string, source_name: "toolName")
  field(:result_json, 3, type: :string, source_name: "resultJson")
end
