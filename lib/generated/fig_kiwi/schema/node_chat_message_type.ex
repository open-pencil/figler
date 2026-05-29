defmodule FigKiwi.Schema.NodeChatMessageType do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:user_message, 0)
  enum_value(:assistant_message, 1)
  enum_value(:tool_message, 2)
  enum_value(:system_message, 3)
end
