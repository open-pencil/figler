defmodule Figler.Schema.ObjectAnimationListItem do
  @moduledoc "Generated Kiwi message module for `ObjectAnimationListItem`."
  use KiwiCodec, kind: :message
  field(:target_node_id, 1, type: Figler.Schema.GUID, source_name: "targetNodeId")
  field(:animation, 2, type: Figler.Schema.PrototypeAction, source_name: "animation")
end
