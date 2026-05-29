defmodule FigKiwi.Schema.OverlayPositionType do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:center, 0)
  enum_value(:top_left, 1)
  enum_value(:top_center, 2)
  enum_value(:top_right, 3)
  enum_value(:bottom_left, 4)
  enum_value(:bottom_center, 5)
  enum_value(:bottom_right, 6)
  enum_value(:manual, 7)
end
