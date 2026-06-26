defmodule Figler.Schema.InheritedVariableEntry do
  @moduledoc "Generated Kiwi message module for `InheritedVariableEntry`."
  use KiwiCodec, kind: :message
  field(:variable_id, 1, type: Figler.Schema.VariableID, source_name: "variableId")
end
