defmodule Figler.Schema.ScrollParallaxBehavior do
  @moduledoc "Generated Kiwi message module for `ScrollParallaxBehavior`."
  use KiwiCodec, kind: :message
  field(:axis, 1, type: {:enum, Figler.Schema.ScrollDirection}, source_name: "axis")
  field(:speed, 2, type: :float, source_name: "speed")
  field(:relative_to_page, 3, type: :bool, source_name: "relativeToPage")
  field(:speed_var, 4, type: Figler.Schema.VariableData, source_name: "speedVar")
  field(:is_deleted, 5, type: :bool, source_name: "isDeleted")
end
