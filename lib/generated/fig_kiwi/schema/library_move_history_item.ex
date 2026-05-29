defmodule FigKiwi.Schema.LibraryMoveHistoryItem do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:source_node_id, 1, type: FigKiwi.Schema.GUID, source_name: "sourceNodeId")
  field(:source_component_key, 2, type: :string, source_name: "sourceComponentKey")
end
