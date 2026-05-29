defmodule FigKiwi.Schema.DeviceRotation do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:none, 0)
  enum_value(:ccw_90, 1)
end
