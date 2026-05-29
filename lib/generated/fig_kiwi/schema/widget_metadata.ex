defmodule FigKiwi.Schema.WidgetMetadata do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:plugin_id, 1, type: :string, source_name: "pluginID")
  field(:plugin_version_id, 2, type: :string, source_name: "pluginVersionID")
  field(:widget_name, 3, type: :string, source_name: "widgetName")
  field(:is_resizable, 4, type: :bool, source_name: "isResizable")
  field(:is_rotatable, 5, type: :bool, source_name: "isRotatable")
end
