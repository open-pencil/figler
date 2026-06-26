defmodule Figler.Schema.TimelinePositionType do
  @moduledoc "Generated Kiwi enum module for `TimelinePositionType`."
  use KiwiCodec, kind: :enum
  enum_value(:absolute, 0)
  enum_value(:relative, 1)
end
