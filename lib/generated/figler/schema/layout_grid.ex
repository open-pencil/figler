defmodule Figler.Schema.LayoutGrid do
  @moduledoc "Generated Kiwi message module for `LayoutGrid`."
  use KiwiCodec, kind: :message
  field(:type, 1, type: {:enum, Figler.Schema.LayoutGridType}, source_name: "type")
  field(:axis, 2, type: {:enum, Figler.Schema.Axis}, source_name: "axis")
  field(:visible, 3, type: :bool, source_name: "visible")
  field(:num_sections, 4, type: :int, source_name: "numSections")
  field(:offset, 5, type: :float, source_name: "offset")
  field(:section_size, 6, type: :float, source_name: "sectionSize")
  field(:gutter_size, 7, type: :float, source_name: "gutterSize")
  field(:color, 8, type: Figler.Schema.Color, source_name: "color")
  field(:pattern, 9, type: {:enum, Figler.Schema.LayoutGridPattern}, source_name: "pattern")
  field(:num_sections_var, 10, type: Figler.Schema.VariableData, source_name: "numSectionsVar")
  field(:offset_var, 11, type: Figler.Schema.VariableData, source_name: "offsetVar")
  field(:section_size_var, 12, type: Figler.Schema.VariableData, source_name: "sectionSizeVar")
  field(:gutter_size_var, 13, type: Figler.Schema.VariableData, source_name: "gutterSizeVar")
end
