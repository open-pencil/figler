defmodule FigKiwi.Schema.ToolData do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:tool_id, 1, type: FigKiwi.Schema.ToolId, source_name: "toolId")

  field(:backing_code_component_id, 2,
    type: FigKiwi.Schema.CodeComponentId,
    source_name: "backingCodeComponentId"
  )

  field(:component_prop_assignments, 3,
    repeated: true,
    type: FigKiwi.Schema.ComponentPropAssignment,
    source_name: "componentPropAssignments"
  )
end
