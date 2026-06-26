defmodule Figler.Schema.PrototypeDevice do
  @moduledoc "Generated Kiwi message module for `PrototypeDevice`."
  use KiwiCodec, kind: :message
  field(:type, 1, type: {:enum, Figler.Schema.PrototypeDeviceType}, source_name: "type")
  field(:size, 2, type: Figler.Schema.Vector, source_name: "size")
  field(:preset_identifier, 3, type: :string, source_name: "presetIdentifier")
  field(:rotation, 4, type: {:enum, Figler.Schema.DeviceRotation}, source_name: "rotation")
end
