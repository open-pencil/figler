defmodule FigKiwi.Schema.IndexFontStyle do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:name, 1, type: :string, source_name: "name")
  field(:postscript, 2, type: :string, source_name: "postscript")
  field(:weight, 3, type: :float, source_name: "weight")
  field(:italic, 4, type: :bool, source_name: "italic")
  field(:stretch, 5, type: :float, source_name: "stretch")

  field(:variation_axis_values, 6,
    repeated: true,
    type: FigKiwi.Schema.IndexFontVariationAxisValue,
    source_name: "variationAxisValues"
  )
end
