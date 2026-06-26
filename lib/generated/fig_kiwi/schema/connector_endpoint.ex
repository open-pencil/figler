defmodule FigKiwi.Schema.ConnectorEndpoint do
  @moduledoc "Generated Kiwi message module for `ConnectorEndpoint`."
  use KiwiCodec, kind: :message
  field(:endpoint_node_id, 1, type: FigKiwi.Schema.GUID, source_name: "endpointNodeID")
  field(:position, 2, type: FigKiwi.Schema.Vector, source_name: "position")
  field(:magnet, 3, type: {:enum, FigKiwi.Schema.ConnectorMagnet}, source_name: "magnet")
  field(:relative_position, 4, type: FigKiwi.Schema.Vector, source_name: "relativePosition")
end
