defmodule Figler.Schema.SlideThemeMapEntry do
  @moduledoc "Generated Kiwi message module for `SlideThemeMapEntry`."
  use KiwiCodec, kind: :message
  field(:theme_id, 1, type: Figler.Schema.ThemeID, source_name: "themeId")
  field(:theme_props, 2, type: Figler.Schema.SlideThemeProps, source_name: "themeProps")
end
