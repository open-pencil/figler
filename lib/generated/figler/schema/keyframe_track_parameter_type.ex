defmodule Figler.Schema.KeyframeTrackParameterType do
  @moduledoc "Generated Kiwi enum module for `KeyframeTrackParameterType`."
  use KiwiCodec, kind: :enum
  enum_value(:invalid, 0)
  enum_value(:manual, 1)
  enum_value(:animation_preset, 2)
end
