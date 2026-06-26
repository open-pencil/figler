defmodule FigKiwi.Schema.ObjectAnimationListItem do
  @moduledoc "Generated Kiwi message module for `ObjectAnimationListItem`."
  use KiwiCodec, kind: :message
  field(:target_node_id, 1, type: FigKiwi.Schema.GUID, source_name: "targetNodeId")
  field(:animation, 2, type: FigKiwi.Schema.PrototypeAction, source_name: "animation")
end
