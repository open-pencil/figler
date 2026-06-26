defmodule FigKiwi.Schema.StyleSetType do
  @moduledoc "Generated Kiwi enum module for `StyleSetType`."
  use KiwiCodec, kind: :enum
  enum_value(:personal, 0)
  enum_value(:team, 1)
  enum_value(:custom, 2)
  enum_value(:frequency, 3)
  enum_value(:temporary, 4)
end
