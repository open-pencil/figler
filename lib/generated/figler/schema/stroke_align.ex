defmodule Figler.Schema.StrokeAlign do
  @moduledoc "Generated Kiwi enum module for `StrokeAlign`."
  use KiwiCodec, kind: :enum
  enum_value(:center, 0)
  enum_value(:inside, 1)
  enum_value(:outside, 2)
  enum_value(:offset, 3)
end
