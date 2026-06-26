defmodule Figler.Schema.ImageScaleMode do
  @moduledoc "Generated Kiwi enum module for `ImageScaleMode`."
  use KiwiCodec, kind: :enum
  enum_value(:stretch, 0)
  enum_value(:fit, 1)
  enum_value(:fill, 2)
  enum_value(:tile, 3)
end
