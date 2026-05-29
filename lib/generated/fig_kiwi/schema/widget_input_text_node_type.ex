defmodule FigKiwi.Schema.WidgetInputTextNodeType do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:widget_controlled, 0)
  enum_value(:rich_text, 1)
end
