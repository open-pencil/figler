defmodule Figler.Schema.ConnectorTextMidpoint do
  @moduledoc "Generated Kiwi message module for `ConnectorTextMidpoint`."
  use KiwiCodec, kind: :message
  field(:section, 1, type: {:enum, Figler.Schema.ConnectorTextSection}, source_name: "section")
  field(:offset, 2, type: :float, source_name: "offset")

  field(:off_axis_offset, 3,
    type: {:enum, Figler.Schema.ConnectorOffAxisOffset},
    source_name: "offAxisOffset"
  )
end
