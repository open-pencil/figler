defmodule Figler.Schema.PasteAssetType do
  @moduledoc "Generated Kiwi enum module for `PasteAssetType`."
  use KiwiCodec, kind: :enum
  enum_value(:unknown, 0)
  enum_value(:variable, 1)
  enum_value(:style_properties, 2)
  enum_value(:style_properties_fill, 3)
  enum_value(:style_properties_stroke, 4)
  enum_value(:style_properties_effect, 5)
end
