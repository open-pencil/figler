defmodule Figler.Schema.InterpolationColorSpace do
  @moduledoc "Generated Kiwi enum module for `InterpolationColorSpace`."
  use KiwiCodec, kind: :enum
  enum_value(:default, 0)
  enum_value(:oklab, 1)
  enum_value(:oklch, 2)
  enum_value(:hsl, 3)
  enum_value(:srgb_linear, 4)
end
