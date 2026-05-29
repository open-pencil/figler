defmodule FigKiwi.Schema.EditScopeInfo do
  @moduledoc false
  use KiwiCodec, kind: :message

  field(:edit_scope_stacks, 1,
    repeated: true,
    type: FigKiwi.Schema.EditScopeStack,
    source_name: "editScopeStacks"
  )

  field(:snapshots, 2,
    repeated: true,
    type: FigKiwi.Schema.EditScopeSnapshot,
    source_name: "snapshots"
  )
end
