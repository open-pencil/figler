defmodule FigKiwi.Schema.ComponentPropDef do
  @moduledoc "Generated Kiwi message module for `ComponentPropDef`."
  use KiwiCodec, kind: :message
  field(:id, 1, type: FigKiwi.Schema.GUID, source_name: "id")
  field(:name, 2, type: :string, source_name: "name")
  field(:initial_value, 3, type: FigKiwi.Schema.ComponentPropValue, source_name: "initialValue")
  field(:sort_position, 4, type: :string, source_name: "sortPosition")
  field(:parent_prop_def_id, 5, type: FigKiwi.Schema.GUID, source_name: "parentPropDefId")
  field(:type, 6, type: {:enum, FigKiwi.Schema.ComponentPropType}, source_name: "type")
  field(:is_deleted, 7, type: :bool, source_name: "isDeleted")

  field(:preferred_values, 8,
    type: FigKiwi.Schema.ComponentPropPreferredValues,
    source_name: "preferredValues"
  )

  field(:var_value, 9, type: FigKiwi.Schema.VariableData, source_name: "varValue")

  field(:parameter_config, 10,
    type: FigKiwi.Schema.ParameterConfig,
    source_name: "parameterConfig"
  )

  field(:description, 11, type: :string, source_name: "description")
  field(:slot_prop_config, 12, type: FigKiwi.Schema.SlotPropConfig, source_name: "slotPropConfig")

  field(:color_array_config, 13,
    type: FigKiwi.Schema.ColorArrayConfig,
    source_name: "colorArrayConfig"
  )
end
