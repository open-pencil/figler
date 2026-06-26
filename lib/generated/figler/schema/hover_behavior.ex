defmodule Figler.Schema.HoverBehavior do
  @moduledoc "Generated Kiwi message module for `HoverBehavior`."
  use KiwiCodec, kind: :message
  field(:transition, 1, type: Figler.Schema.BehaviorTransition, source_name: "transition")
  field(:state, 2, type: Figler.Schema.NodeChange, source_name: "state")
  field(:is_deleted, 3, type: :bool, source_name: "isDeleted")
end
