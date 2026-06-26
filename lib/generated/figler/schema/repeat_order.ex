defmodule Figler.Schema.RepeatOrder do
  @moduledoc "Generated Kiwi enum module for `RepeatOrder`."
  use KiwiCodec, kind: :enum
  enum_value(:forward, 0)
  enum_value(:reverse, 1)
end
