defmodule FigKiwi.Schema.TransitionDirection do
  @moduledoc "Generated Kiwi enum module for `TransitionDirection`."
  use KiwiCodec, kind: :enum
  enum_value(:forward, 0)
  enum_value(:reverse, 1)
end
