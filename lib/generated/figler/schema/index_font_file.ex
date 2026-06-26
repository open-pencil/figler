defmodule Figler.Schema.IndexFontFile do
  @moduledoc "Generated Kiwi message module for `IndexFontFile`."
  use KiwiCodec, kind: :message
  field(:filename, 1, type: :string, source_name: "filename")
  field(:version, 2, type: :uint, source_name: "version")
  field(:family, 3, type: :string, source_name: "family")
  field(:styles, 4, repeated: true, type: Figler.Schema.IndexFontStyle, source_name: "styles")

  field(:variation_axes, 5,
    repeated: true,
    type: Figler.Schema.IndexFontVariationAxis,
    source_name: "variationAxes"
  )

  field(:use_font_optical_size, 6, type: :bool, source_name: "useFontOpticalSize")
end
