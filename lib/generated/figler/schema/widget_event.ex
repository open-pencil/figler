defmodule Figler.Schema.WidgetEvent do
  @moduledoc "Generated Kiwi enum module for `WidgetEvent`."
  use KiwiCodec, kind: :enum
  enum_value(:mouse_down, 0)
  enum_value(:click, 1)
  enum_value(:text_edit_end, 2)
  enum_value(:attached_stickables_changed, 3)
  enum_value(:stuck_status_changed, 4)
end
