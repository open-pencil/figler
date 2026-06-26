defmodule FigKiwi.Schema.SlideNumber do
  @moduledoc "Generated Kiwi enum module for `SlideNumber`."
  use KiwiCodec, kind: :enum
  enum_value(:none, 0)
  enum_value(:slide, 1)
  enum_value(:section, 2)
  enum_value(:subsection, 3)
  enum_value(:total_within_deck, 4)
  enum_value(:total_within_section, 5)
end
