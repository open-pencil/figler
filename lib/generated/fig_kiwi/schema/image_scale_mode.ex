defmodule FigKiwi.Schema.ImageScaleMode do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:stretch, 0)
  enum_value(:fit, 1)
  enum_value(:fill, 2)
  enum_value(:tile, 3)
end
