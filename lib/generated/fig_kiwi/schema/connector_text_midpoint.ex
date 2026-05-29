defmodule FigKiwi.Schema.ConnectorTextMidpoint do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:section, 1, type: {:enum, FigKiwi.Schema.ConnectorTextSection}, source_name: "section")
  field(:offset, 2, type: :float, source_name: "offset")

  field(:off_axis_offset, 3,
    type: {:enum, FigKiwi.Schema.ConnectorOffAxisOffset},
    source_name: "offAxisOffset"
  )
end
