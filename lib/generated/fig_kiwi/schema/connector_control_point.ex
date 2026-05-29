defmodule FigKiwi.Schema.ConnectorControlPoint do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:position, 1, type: FigKiwi.Schema.Vector, source_name: "position")
  field(:axis, 2, type: FigKiwi.Schema.Vector, source_name: "axis")
end
