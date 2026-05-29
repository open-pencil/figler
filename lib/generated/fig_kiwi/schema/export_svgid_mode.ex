defmodule FigKiwi.Schema.ExportSVGIDMode do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:if_needed, 0)
  enum_value(:always, 1)
end
