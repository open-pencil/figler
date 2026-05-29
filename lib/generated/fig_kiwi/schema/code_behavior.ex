defmodule FigKiwi.Schema.CodeBehavior do
  @moduledoc false
  use KiwiCodec, kind: :message

  field(:code_component_id, 1,
    type: FigKiwi.Schema.CodeComponentId,
    source_name: "codeComponentId"
  )

  field(:component_prop_assignments, 2,
    repeated: true,
    type: FigKiwi.Schema.ComponentPropAssignment,
    source_name: "componentPropAssignments"
  )

  field(:is_deleted, 3, type: :bool, source_name: "isDeleted")
end
