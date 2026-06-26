defmodule FigKiwi.Schema.SlideThemeProps do
  @moduledoc "Generated Kiwi message module for `SlideThemeProps`."
  use KiwiCodec, kind: :message
  field(:theme_version, 1, type: :string, source_name: "themeVersion")
  field(:variable_set_id, 2, type: FigKiwi.Schema.VariableSetID, source_name: "variableSetId")

  field(:text_style_ids, 3,
    repeated: true,
    type: FigKiwi.Schema.StyleId,
    source_name: "textStyleIds"
  )

  field(:is_text_color_manually_selected, 4,
    type: :bool,
    source_name: "isTextColorManuallySelected"
  )

  field(:is_border_color_manually_selected, 5,
    type: :bool,
    source_name: "isBorderColorManuallySelected"
  )

  field(:subscribed_theme_ref, 6,
    type: FigKiwi.Schema.AssetRef,
    source_name: "subscribedThemeRef"
  )

  field(:schema_version, 7, type: :uint, source_name: "schemaVersion")
  field(:is_generated_from_design, 8, type: :bool, source_name: "isGeneratedFromDesign")
end
