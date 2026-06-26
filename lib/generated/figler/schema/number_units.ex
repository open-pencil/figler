defmodule Figler.Schema.NumberUnits do
  @moduledoc "Generated Kiwi enum module for `NumberUnits`."
  use KiwiCodec, kind: :enum
  enum_value(:raw, 0)
  enum_value(:pixels, 1)
  enum_value(:percent, 2)
end
