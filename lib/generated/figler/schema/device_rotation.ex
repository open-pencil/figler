defmodule Figler.Schema.DeviceRotation do
  @moduledoc "Generated Kiwi enum module for `DeviceRotation`."
  use KiwiCodec, kind: :enum
  enum_value(:none, 0)
  enum_value(:ccw_90, 1)
end
