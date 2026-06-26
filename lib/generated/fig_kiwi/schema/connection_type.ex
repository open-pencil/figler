defmodule FigKiwi.Schema.ConnectionType do
  @moduledoc "Generated Kiwi enum module for `ConnectionType`."
  use KiwiCodec, kind: :enum
  enum_value(:none, 0)
  enum_value(:internal_node, 1)
  enum_value(:url, 2)
  enum_value(:back, 3)
  enum_value(:close, 4)
  enum_value(:set_variable, 5)
  enum_value(:update_media_runtime, 6)
  enum_value(:conditional, 7)
  enum_value(:set_variable_mode, 8)
  enum_value(:object_animation, 9)
  enum_value(:update_animation_timeline_state, 10)
end
