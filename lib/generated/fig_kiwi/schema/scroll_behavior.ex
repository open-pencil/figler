defmodule FigKiwi.Schema.ScrollBehavior do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:scrolls, 0)
  enum_value(:fixed_when_child_of_scrolling_frame, 1)
  enum_value(:sticky_scrolls, 2)
end
