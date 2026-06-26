defmodule Figler.Schema.StackCounterAlign do
  @moduledoc "Generated Kiwi enum module for `StackCounterAlign`."
  use KiwiCodec, kind: :enum
  enum_value(:min, 0)
  enum_value(:center, 1)
  enum_value(:max, 2)
  enum_value(:stretch, 3)
  enum_value(:auto, 4)
  enum_value(:baseline, 5)
end
