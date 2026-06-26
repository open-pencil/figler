defmodule Figler.Schema.EditScopeSnapshot do
  @moduledoc "Generated Kiwi message module for `EditScopeSnapshot`."
  use KiwiCodec, kind: :message
  field(:frames, 1, repeated: true, type: Figler.Schema.EditScopeStack, source_name: "frames")

  field(:node_change_field_numbers, 2,
    repeated: true,
    type: :uint,
    source_name: "nodeChangeFieldNumbers"
  )
end
