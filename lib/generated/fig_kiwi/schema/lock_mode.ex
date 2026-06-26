defmodule FigKiwi.Schema.LockMode do
  @moduledoc "Generated Kiwi enum module for `LockMode`."
  use KiwiCodec, kind: :enum
  enum_value(:none, 0)
  enum_value(:all, 1)
  enum_value(:background_only, 2)
end
