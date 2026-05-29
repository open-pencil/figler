defmodule FigKiwi.Schema.PressBehavior do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:transition, 1, type: FigKiwi.Schema.BehaviorTransition, source_name: "transition")
  field(:state, 2, type: FigKiwi.Schema.NodeChange, source_name: "state")
  field(:is_deleted, 3, type: :bool, source_name: "isDeleted")
end
