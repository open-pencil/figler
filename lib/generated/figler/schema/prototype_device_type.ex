defmodule Figler.Schema.PrototypeDeviceType do
  @moduledoc "Generated Kiwi enum module for `PrototypeDeviceType`."
  use KiwiCodec, kind: :enum
  enum_value(:none, 0)
  enum_value(:preset, 1)
  enum_value(:custom, 2)
  enum_value(:presentation, 3)
end
