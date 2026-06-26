defmodule Figler.Schema.EditScopeStack do
  @moduledoc "Generated Kiwi message module for `EditScopeStack`."
  use KiwiCodec, kind: :message
  field(:stack, 1, repeated: true, type: Figler.Schema.EditScope, source_name: "stack")
end
