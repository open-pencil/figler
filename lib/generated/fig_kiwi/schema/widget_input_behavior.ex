defmodule FigKiwi.Schema.WidgetInputBehavior do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:wrap, 0)
  enum_value(:truncate, 1)
  enum_value(:multiline, 2)
end
