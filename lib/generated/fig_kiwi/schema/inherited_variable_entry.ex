defmodule FigKiwi.Schema.InheritedVariableEntry do
  @moduledoc "Generated Kiwi message module for `InheritedVariableEntry`."
  use KiwiCodec, kind: :message
  field(:variable_id, 1, type: FigKiwi.Schema.VariableID, source_name: "variableId")
end
