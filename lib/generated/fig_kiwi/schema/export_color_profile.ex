defmodule FigKiwi.Schema.ExportColorProfile do
  @moduledoc "Generated Kiwi enum module for `ExportColorProfile`."
  use KiwiCodec, kind: :enum
  enum_value(:document, 0)
  enum_value(:srgb, 1)
  enum_value(:display_p3_v4, 2)
  enum_value(:cmyk, 3)
end
