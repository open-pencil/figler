defmodule FigKiwi.Schema.ComponentPropAssignment do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:def_id, 1, type: FigKiwi.Schema.GUID, source_name: "defID")
  field(:value, 2, type: FigKiwi.Schema.ComponentPropValue, source_name: "value")
  field(:var_value, 3, type: FigKiwi.Schema.VariableData, source_name: "varValue")

  field(:legacy_derived_text_data, 4,
    type: FigKiwi.Schema.DerivedTextData,
    source_name: "legacyDerivedTextData"
  )
end
