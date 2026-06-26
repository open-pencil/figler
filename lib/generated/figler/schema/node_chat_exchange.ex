defmodule Figler.Schema.NodeChatExchange do
  @moduledoc "Generated Kiwi message module for `NodeChatExchange`."
  use KiwiCodec, kind: :message
  field(:node, 1, type: Figler.Schema.GUID, source_name: "node")

  field(:messages, 2,
    repeated: true,
    type: Figler.Schema.NodeChatMessage,
    source_name: "messages"
  )

  field(:is_typing, 3, type: :bool, source_name: "isTyping")

  field(:file_updates, 4,
    repeated: true,
    type: Figler.Schema.FileUpdate,
    source_name: "fileUpdates"
  )
end
