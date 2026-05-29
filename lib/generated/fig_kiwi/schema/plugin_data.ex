defmodule FigKiwi.Schema.PluginData do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:plugin_id, 1, type: :string, source_name: "pluginID")
  field(:value, 2, type: :string, source_name: "value")
  field(:key, 3, type: :string, source_name: "key")
end
