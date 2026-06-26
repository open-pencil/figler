defmodule FigKiwi.Schema.NodeChatMessageType do
  @moduledoc "Generated Kiwi enum module for `NodeChatMessageType`."
  use KiwiCodec, kind: :enum
  enum_value(:user_message, 0)
  enum_value(:assistant_message, 1)
  enum_value(:tool_message, 2)
  enum_value(:system_message, 3)
end
