defmodule FigKiwi.Schema.WidgetPointer do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:node_id, 1, type: FigKiwi.Schema.GUID, source_name: "nodeId")
end
