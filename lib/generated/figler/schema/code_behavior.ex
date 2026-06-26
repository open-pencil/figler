defmodule Figler.Schema.CodeBehavior do
  @moduledoc "Generated Kiwi message module for `CodeBehavior`."
  use KiwiCodec, kind: :message

  field(:code_component_id, 1,
    type: Figler.Schema.CodeComponentId,
    source_name: "codeComponentId"
  )

  field(:component_prop_assignments, 2,
    repeated: true,
    type: Figler.Schema.ComponentPropAssignment,
    source_name: "componentPropAssignments"
  )

  field(:is_deleted, 3, type: :bool, source_name: "isDeleted")
end
