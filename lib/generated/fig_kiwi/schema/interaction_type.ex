defmodule FigKiwi.Schema.InteractionType do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:on_click, 0)
  enum_value(:after_timeout, 1)
  enum_value(:mouse_in, 2)
  enum_value(:mouse_out, 3)
  enum_value(:on_hover, 4)
  enum_value(:mouse_down, 5)
  enum_value(:mouse_up, 6)
  enum_value(:on_press, 7)
  enum_value(:none, 8)
  enum_value(:drag, 9)
  enum_value(:on_key_down, 10)
  enum_value(:on_voice, 11)
  enum_value(:on_media_hit, 12)
  enum_value(:on_media_end, 13)
  enum_value(:mouse_enter, 14)
  enum_value(:mouse_leave, 15)
end
