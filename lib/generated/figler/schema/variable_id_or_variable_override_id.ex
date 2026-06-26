defmodule Figler.Schema.VariableIdOrVariableOverrideId do
  @moduledoc "Generated Kiwi message module for `VariableIdOrVariableOverrideId`."
  use KiwiCodec, kind: :message
  field(:variable_id, 1, type: Figler.Schema.VariableID, source_name: "variableId")

  field(:variable_override_id, 2,
    type: Figler.Schema.VariableOverrideId,
    source_name: "variableOverrideId"
  )
end
