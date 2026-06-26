defmodule Figler.Schema.LibraryMoveHistoryItem do
  @moduledoc "Generated Kiwi message module for `LibraryMoveHistoryItem`."
  use KiwiCodec, kind: :message
  field(:source_node_id, 1, type: Figler.Schema.GUID, source_name: "sourceNodeId")
  field(:source_component_key, 2, type: :string, source_name: "sourceComponentKey")
end
