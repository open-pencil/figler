defmodule FigKiwi.Schema.PluginRelaunchData do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:plugin_id, 1, type: :string, source_name: "pluginID")
  field(:message, 2, type: :string, source_name: "message")
  field(:command, 3, type: :string, source_name: "command")
  field(:is_deleted, 4, type: :bool, source_name: "isDeleted")
  field(:custom_tool_id, 5, type: FigKiwi.Schema.CodeComponentId, source_name: "customToolId")
end
