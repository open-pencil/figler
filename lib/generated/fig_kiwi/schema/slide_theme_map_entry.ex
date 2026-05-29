defmodule FigKiwi.Schema.SlideThemeMapEntry do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:theme_id, 1, type: FigKiwi.Schema.ThemeID, source_name: "themeId")
  field(:theme_props, 2, type: FigKiwi.Schema.SlideThemeProps, source_name: "themeProps")
end
