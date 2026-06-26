defmodule Figler.Schema.StackAlign do
  @moduledoc "Generated Kiwi enum module for `StackAlign`."
  use KiwiCodec, kind: :enum
  enum_value(:min, 0)
  enum_value(:center, 1)
  enum_value(:max, 2)
  enum_value(:baseline, 3)
end
