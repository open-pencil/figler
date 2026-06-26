defmodule FigKiwi.Schema.RepeaterPositionOverrides do
  @moduledoc "Generated Kiwi message module for `RepeaterPositionOverrides`."
  use KiwiCodec, kind: :message
  field(:position, 1, type: FigKiwi.Schema.ParentIndex, source_name: "position")
  field(:overrides, 2, repeated: true, type: FigKiwi.Schema.NodeChange, source_name: "overrides")
end
