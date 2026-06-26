defmodule Figler.Schema.IndexFontStyle do
  @moduledoc "Generated Kiwi message module for `IndexFontStyle`."
  use KiwiCodec, kind: :message
  field(:name, 1, type: :string, source_name: "name")
  field(:postscript, 2, type: :string, source_name: "postscript")
  field(:weight, 3, type: :float, source_name: "weight")
  field(:italic, 4, type: :bool, source_name: "italic")
  field(:stretch, 5, type: :float, source_name: "stretch")

  field(:variation_axis_values, 6,
    repeated: true,
    type: Figler.Schema.IndexFontVariationAxisValue,
    source_name: "variationAxisValues"
  )
end
