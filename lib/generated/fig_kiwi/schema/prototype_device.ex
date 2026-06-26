defmodule FigKiwi.Schema.PrototypeDevice do
  @moduledoc "Generated Kiwi message module for `PrototypeDevice`."
  use KiwiCodec, kind: :message
  field(:type, 1, type: {:enum, FigKiwi.Schema.PrototypeDeviceType}, source_name: "type")
  field(:size, 2, type: FigKiwi.Schema.Vector, source_name: "size")
  field(:preset_identifier, 3, type: :string, source_name: "presetIdentifier")
  field(:rotation, 4, type: {:enum, FigKiwi.Schema.DeviceRotation}, source_name: "rotation")
end
