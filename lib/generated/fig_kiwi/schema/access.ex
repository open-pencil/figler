defmodule FigKiwi.Schema.Access do
  @moduledoc "Generated Kiwi enum module for `Access`."
  use KiwiCodec, kind: :enum
  enum_value(:read_only, 0)
  enum_value(:read_write, 1)
end
