defmodule Figler.Schema.ToolData do
  @moduledoc "Generated Kiwi message module for `ToolData`."
  use KiwiCodec, kind: :message
  field(:tool_id, 1, type: Figler.Schema.ToolId, source_name: "toolId")

  field(:backing_code_component_id, 2,
    type: Figler.Schema.CodeComponentId,
    source_name: "backingCodeComponentId"
  )

  field(:component_prop_assignments, 3,
    repeated: true,
    type: Figler.Schema.ComponentPropAssignment,
    source_name: "componentPropAssignments"
  )
end
