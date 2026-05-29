defmodule FigKiwi.Schema.ObjectAnimationListItem do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:target_node_id, 1, type: FigKiwi.Schema.GUID, source_name: "targetNodeId")
  field(:animation, 2, type: FigKiwi.Schema.PrototypeAction, source_name: "animation")
end
