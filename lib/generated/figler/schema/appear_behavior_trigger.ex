defmodule Figler.Schema.AppearBehaviorTrigger do
  @moduledoc "Generated Kiwi enum module for `AppearBehaviorTrigger`."
  use KiwiCodec, kind: :enum
  enum_value(:page_load, 1)
  enum_value(:this_layer_in_view, 2)
  enum_value(:other_layer_in_view, 3)
  enum_value(:scroll_direction, 4)
end
