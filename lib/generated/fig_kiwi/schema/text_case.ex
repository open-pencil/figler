defmodule FigKiwi.Schema.TextCase do
  @moduledoc "Generated Kiwi enum module for `TextCase`."
  use KiwiCodec, kind: :enum
  enum_value(:original, 0)
  enum_value(:upper, 1)
  enum_value(:lower, 2)
  enum_value(:title, 3)
  enum_value(:small_caps, 4)
  enum_value(:small_caps_forced, 5)
end
