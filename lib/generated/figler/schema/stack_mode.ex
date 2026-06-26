defmodule Figler.Schema.StackMode do
  @moduledoc "Generated Kiwi enum module for `StackMode`."
  use KiwiCodec, kind: :enum
  enum_value(:none, 0)
  enum_value(:horizontal, 1)
  enum_value(:vertical, 2)
  enum_value(:grid, 3)
end
