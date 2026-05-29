defmodule FigKiwi.Schema.ExportBackgroundType do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:solid, 0)
  enum_value(:transparent, 1)
  enum_value(:grid, 2)
end
