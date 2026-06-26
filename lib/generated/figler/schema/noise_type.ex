defmodule Figler.Schema.NoiseType do
  @moduledoc "Generated Kiwi enum module for `NoiseType`."
  use KiwiCodec, kind: :enum
  enum_value(:multitone, 0)
  enum_value(:monotone, 1)
  enum_value(:duotone, 2)
end
