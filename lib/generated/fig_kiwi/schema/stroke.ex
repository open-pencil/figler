defmodule FigKiwi.Schema.Stroke do
  @moduledoc "Generated Kiwi message module for `Stroke`."
  use KiwiCodec, kind: :message
  field(:stroke_id, 1, type: :int, source_name: "strokeId")
  field(:stroke_weight, 2, type: :float, source_name: "strokeWeight")
  field(:stroke_weight_var, 3, type: FigKiwi.Schema.VariableData, source_name: "strokeWeightVar")
  field(:stroke_paint, 4, repeated: true, type: FigKiwi.Schema.Paint, source_name: "strokePaint")

  field(:style_id_for_stroke_fill, 5,
    type: FigKiwi.Schema.StyleId,
    source_name: "styleIdForStrokeFill"
  )

  field(:stroke_align, 6, type: {:enum, FigKiwi.Schema.StrokeAlign}, source_name: "strokeAlign")
  field(:stroke_cap, 7, type: {:enum, FigKiwi.Schema.StrokeCap}, source_name: "strokeCap")
  field(:stroke_cap_size, 8, type: FigKiwi.Schema.Number, source_name: "strokeCapSize")
  field(:stroke_join, 9, type: {:enum, FigKiwi.Schema.StrokeJoin}, source_name: "strokeJoin")
  field(:miter_limit, 10, type: :float, source_name: "miterLimit")
  field(:dash_pattern, 11, repeated: true, type: :float, source_name: "dashPattern")
  field(:path_trim, 12, type: FigKiwi.Schema.OptionalVector, source_name: "pathTrim")
  field(:stroke_offset, 13, type: :float, source_name: "strokeOffset")
  field(:is_deleted, 14, type: :bool, source_name: "isDeleted")
end
