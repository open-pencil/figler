defmodule FigKiwi.Schema.ManagedStringFormatType do
  @moduledoc "Generated Kiwi enum module for `ManagedStringFormatType`."
  use KiwiCodec, kind: :enum
  enum_value(:text, 0)
  enum_value(:date, 1)
  enum_value(:time, 2)
  enum_value(:number, 3)
end
