defmodule Figler.Schema.EditScopeInfo do
  @moduledoc "Generated Kiwi message module for `EditScopeInfo`."
  use KiwiCodec, kind: :message

  field(:edit_scope_stacks, 1,
    repeated: true,
    type: Figler.Schema.EditScopeStack,
    source_name: "editScopeStacks"
  )

  field(:snapshots, 2,
    repeated: true,
    type: Figler.Schema.EditScopeSnapshot,
    source_name: "snapshots"
  )
end
