defmodule Figler.Schema.PluginData do
  @moduledoc "Generated Kiwi message module for `PluginData`."
  use KiwiCodec, kind: :message
  field(:plugin_id, 1, type: :string, source_name: "pluginID")
  field(:value, 2, type: :string, source_name: "value")
  field(:key, 3, type: :string, source_name: "key")
end
