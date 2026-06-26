defmodule Figler.Schema.NodeChatMessage do
  @moduledoc "Generated Kiwi message module for `NodeChatMessage`."
  use KiwiCodec, kind: :message
  field(:id, 1, type: Figler.Schema.GUID, source_name: "id")
  field(:type, 2, type: {:enum, Figler.Schema.NodeChatMessageType}, source_name: "type")
  field(:user_id, 3, type: :string, source_name: "userId")
  field(:text_content, 4, type: :string, source_name: "textContent")
  field(:sent_at, 5, type: :uint, source_name: "sentAt")

  field(:tool_calls, 6,
    repeated: true,
    type: Figler.Schema.NodeChatToolCall,
    source_name: "toolCalls"
  )

  field(:tool_results, 7,
    repeated: true,
    type: Figler.Schema.NodeChatToolResult,
    source_name: "toolResults"
  )

  field(:sent_at64, 8, type: :uint64, source_name: "sentAt64")
end
