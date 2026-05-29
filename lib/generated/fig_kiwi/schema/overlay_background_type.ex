defmodule FigKiwi.Schema.OverlayBackgroundType do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:none, 0)
  enum_value(:solid_color, 1)
end
