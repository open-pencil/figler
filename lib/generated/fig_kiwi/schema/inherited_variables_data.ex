defmodule FigKiwi.Schema.InheritedVariablesData do
  @moduledoc false
  use KiwiCodec, kind: :message

  field(:variable_ids, 1,
    repeated: true,
    type: FigKiwi.Schema.InheritedVariableEntry,
    source_name: "variableIds"
  )
end
