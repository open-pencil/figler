defmodule Figler.Schema.SlideThemeData do
  @moduledoc "Generated Kiwi message module for `SlideThemeData`."
  use KiwiCodec, kind: :message
  field(:theme_id, 1, type: Figler.Schema.ThemeID, source_name: "themeID")
  field(:version, 2, type: :string, source_name: "version")
end
