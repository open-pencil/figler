defmodule FigKiwi.Schema.OverlayBackgroundInteraction do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:none, 0)
  enum_value(:close_on_click_outside, 1)
end
