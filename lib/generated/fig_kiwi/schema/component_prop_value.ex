defmodule FigKiwi.Schema.ComponentPropValue do
  @moduledoc "Generated Kiwi message module for `ComponentPropValue`."
  use KiwiCodec, kind: :message
  field(:bool_value, 1, type: :bool, source_name: "boolValue")
  field(:text_value, 2, type: FigKiwi.Schema.TextData, source_name: "textValue")
  field(:guid_value, 3, type: FigKiwi.Schema.GUID, source_name: "guidValue")
  field(:float_value, 4, type: :float, source_name: "floatValue")
  field(:easing_data, 5, type: FigKiwi.Schema.EasingData, source_name: "easingData")
  field(:vector_value, 6, type: FigKiwi.Schema.Vector, source_name: "vectorValue")
  field(:line_value, 7, type: FigKiwi.Schema.Line, source_name: "lineValue")
  field(:circle_value, 8, type: FigKiwi.Schema.Circle, source_name: "circleValue")
  field(:rotation3_d_value, 9, type: FigKiwi.Schema.Rotation3D, source_name: "rotation3DValue")

  field(:circle_point_value, 10,
    type: FigKiwi.Schema.CirclePoint,
    source_name: "circlePointValue"
  )

  field(:gradient_value, 11, type: FigKiwi.Schema.Gradient, source_name: "gradientValue")
  field(:color_point_value, 12, type: FigKiwi.Schema.ColorPoint, source_name: "colorPointValue")
end
