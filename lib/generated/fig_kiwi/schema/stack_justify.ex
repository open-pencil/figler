defmodule FigKiwi.Schema.StackJustify do
  @moduledoc "Generated Kiwi enum module for `StackJustify`."
  use KiwiCodec, kind: :enum
  enum_value(:min, 0)
  enum_value(:center, 1)
  enum_value(:max, 2)
  enum_value(:space_evenly, 3)
  enum_value(:space_between, 4)
end
