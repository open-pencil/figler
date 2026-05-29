defmodule FigKiwi.Schema.RepeaterPositionOverrides do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:position, 1, type: FigKiwi.Schema.ParentIndex, source_name: "position")
  field(:overrides, 2, repeated: true, type: FigKiwi.Schema.NodeChange, source_name: "overrides")
end
