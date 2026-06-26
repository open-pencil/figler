defmodule Figler.Schema.ComponentPropAssignment do
  @moduledoc "Generated Kiwi message module for `ComponentPropAssignment`."
  use KiwiCodec, kind: :message
  field(:def_id, 1, type: Figler.Schema.GUID, source_name: "defID")
  field(:value, 2, type: Figler.Schema.ComponentPropValue, source_name: "value")
  field(:var_value, 3, type: Figler.Schema.VariableData, source_name: "varValue")

  field(:legacy_derived_text_data, 4,
    type: Figler.Schema.DerivedTextData,
    source_name: "legacyDerivedTextData"
  )
end
