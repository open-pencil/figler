defmodule Figler.Schema.WidgetPropertyMenuItemType do
  @moduledoc "Generated Kiwi enum module for `WidgetPropertyMenuItemType`."
  use KiwiCodec, kind: :enum
  enum_value(:action, 0)
  enum_value(:separator, 1)
  enum_value(:color, 2)
  enum_value(:dropdown, 3)
  enum_value(:color_selector, 4)
  enum_value(:toggle, 5)
  enum_value(:link, 6)
end
