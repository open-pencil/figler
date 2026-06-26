defmodule Figler.Schema.InheritedVariablesData do
  @moduledoc "Generated Kiwi message module for `InheritedVariablesData`."
  use KiwiCodec, kind: :message

  field(:variable_ids, 1,
    repeated: true,
    type: Figler.Schema.InheritedVariableEntry,
    source_name: "variableIds"
  )
end
