defmodule FigKiwi.Schema.LineType do
  @moduledoc "Generated Kiwi enum module for `LineType`."
  use KiwiCodec, kind: :enum
  enum_value(:plain, 0)
  enum_value(:ordered_list, 1)
  enum_value(:unordered_list, 2)
  enum_value(:blockquote, 3)
  enum_value(:header, 4)
end
