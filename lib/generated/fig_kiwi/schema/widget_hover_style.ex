defmodule FigKiwi.Schema.WidgetHoverStyle do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:fill_paints, 1, repeated: true, type: FigKiwi.Schema.Paint, source_name: "fillPaints")

  field(:stroke_paints, 2,
    repeated: true,
    type: FigKiwi.Schema.Paint,
    source_name: "strokePaints"
  )

  field(:opacity, 3, type: :float, source_name: "opacity")
  field(:are_fill_paints_set, 4, type: :bool, source_name: "areFillPaintsSet")
  field(:are_stroke_paints_set, 5, type: :bool, source_name: "areStrokePaintsSet")
  field(:is_opacity_set, 6, type: :bool, source_name: "isOpacitySet")
end
