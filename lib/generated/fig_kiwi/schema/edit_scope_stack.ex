defmodule FigKiwi.Schema.EditScopeStack do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:stack, 1, repeated: true, type: FigKiwi.Schema.EditScope, source_name: "stack")
end
