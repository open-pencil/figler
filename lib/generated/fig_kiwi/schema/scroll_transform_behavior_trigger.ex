defmodule FigKiwi.Schema.ScrollTransformBehaviorTrigger do
  @moduledoc "Generated Kiwi enum module for `ScrollTransformBehaviorTrigger`."
  use KiwiCodec, kind: :enum
  enum_value(:page_height, 1)
  enum_value(:this_layer_in_view, 2)
  enum_value(:other_layer_in_view, 3)
end
