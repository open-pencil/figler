defmodule Figler.Schema.ResponsiveTextStyleVariant do
  @moduledoc "Generated Kiwi message module for `ResponsiveTextStyleVariant`."
  use KiwiCodec, kind: :message
  field(:min_width, 1, type: :float, source_name: "minWidth")
  field(:fields, 2, type: Figler.Schema.NodeChange, source_name: "fields")
  field(:variable_font_size, 3, type: Figler.Schema.VariableData, source_name: "variableFontSize")

  field(:variable_line_height, 4,
    type: Figler.Schema.VariableData,
    source_name: "variableLineHeight"
  )

  field(:variable_letter_spacing, 5,
    type: Figler.Schema.VariableData,
    source_name: "variableLetterSpacing"
  )

  field(:variable_paragraph_spacing, 6,
    type: Figler.Schema.VariableData,
    source_name: "variableParagraphSpacing"
  )

  field(:name, 7, type: :string, source_name: "name")
end
