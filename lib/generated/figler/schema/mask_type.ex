defmodule Figler.Schema.MaskType do
  @moduledoc "Generated Kiwi enum module for `MaskType`."
  use KiwiCodec, kind: :enum
  enum_value(:alpha, 0)
  enum_value(:outline, 1)
  enum_value(:luminance, 2)
end
