defmodule FigKiwi.Schema.VariableAnyValue do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:bool_value, 1, type: :bool, source_name: "boolValue")
  field(:text_value, 2, type: :string, source_name: "textValue")
  field(:float_value, 3, type: :float, source_name: "floatValue")
  field(:alias, 4, type: FigKiwi.Schema.VariableID, source_name: "alias")
  field(:color_value, 5, type: FigKiwi.Schema.Color, source_name: "colorValue")
  field(:expression_value, 6, type: FigKiwi.Schema.Expression, source_name: "expressionValue")
  field(:map_value, 7, type: FigKiwi.Schema.VariableMap, source_name: "mapValue")
  field(:symbol_id_value, 8, type: FigKiwi.Schema.SymbolId, source_name: "symbolIdValue")

  field(:font_style_value, 9,
    type: FigKiwi.Schema.VariableFontStyle,
    source_name: "fontStyleValue"
  )

  field(:text_data_value, 10, type: FigKiwi.Schema.TextData, source_name: "textDataValue")

  field(:node_field_alias_value, 11,
    type: FigKiwi.Schema.NodeFieldAlias,
    source_name: "nodeFieldAliasValue"
  )

  field(:cms_alias_value, 12, type: FigKiwi.Schema.CMSAlias, source_name: "cmsAliasValue")
  field(:prop_ref_value, 13, type: FigKiwi.Schema.PropRefValue, source_name: "propRefValue")
  field(:image_value, 14, type: FigKiwi.Schema.ImageParameterValue, source_name: "imageValue")

  field(:managed_string_alias_value, 15,
    type: FigKiwi.Schema.ManagedStringAlias,
    source_name: "managedStringAliasValue"
  )

  field(:link_value, 16, type: FigKiwi.Schema.Hyperlink, source_name: "linkValue")

  field(:js_runtime_alias_value, 17,
    type: FigKiwi.Schema.JsRuntimeAlias,
    source_name: "jsRuntimeAliasValue"
  )

  field(:slot_content_id_value, 18,
    type: FigKiwi.Schema.SlotContentId,
    source_name: "slotContentIdValue"
  )

  field(:keyframe_track_id_value, 19,
    type: FigKiwi.Schema.KeyframeTrackId,
    source_name: "keyframeTrackIdValue"
  )

  field(:keyframe_track_parameter_value, 20,
    type: FigKiwi.Schema.KeyframeTrackParameterValue,
    source_name: "keyframeTrackParameterValue"
  )

  field(:easing_value, 21, type: FigKiwi.Schema.EasingData, source_name: "easingValue")
  field(:vector_value, 22, type: FigKiwi.Schema.Vector, source_name: "vectorValue")
  field(:color_array_value, 23, type: FigKiwi.Schema.ColorArray, source_name: "colorArrayValue")
  field(:line_value, 24, type: FigKiwi.Schema.Line, source_name: "lineValue")
  field(:circle_value, 25, type: FigKiwi.Schema.Circle, source_name: "circleValue")
  field(:rotation3_d_value, 26, type: FigKiwi.Schema.Rotation3D, source_name: "rotation3DValue")

  field(:circle_point_value, 27,
    type: FigKiwi.Schema.CirclePoint,
    source_name: "circlePointValue"
  )

  field(:gradient_value, 28, type: FigKiwi.Schema.Gradient, source_name: "gradientValue")
  field(:color_point_value, 29, type: FigKiwi.Schema.ColorPoint, source_name: "colorPointValue")
end
