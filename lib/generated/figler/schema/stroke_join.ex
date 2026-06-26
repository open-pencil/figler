defmodule Figler.Schema.StrokeJoin do
  @moduledoc "Generated Kiwi enum module for `StrokeJoin`."
  use KiwiCodec, kind: :enum
  enum_value(:miter, 0)
  enum_value(:bevel, 1)
  enum_value(:round, 2)
end
