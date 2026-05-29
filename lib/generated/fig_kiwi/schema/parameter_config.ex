defmodule FigKiwi.Schema.ParameterConfig do
  @moduledoc false
  use KiwiCodec, kind: :message

  field(:number_prop_config, 1,
    type: FigKiwi.Schema.NumberPropConfig,
    source_name: "numberPropConfig"
  )

  field(:control, 2, type: {:enum, FigKiwi.Schema.ParameterConfigControl}, source_name: "control")
  field(:slider_config, 3, type: FigKiwi.Schema.SliderConfig, source_name: "sliderConfig")
  field(:label, 4, type: FigKiwi.Schema.VariableData, source_name: "label")
  field(:input_config, 5, type: FigKiwi.Schema.InputConfig, source_name: "inputConfig")
  field(:select_config, 6, type: FigKiwi.Schema.SelectConfig, source_name: "selectConfig")
  field(:point_config, 7, type: FigKiwi.Schema.PointConfig, source_name: "pointConfig")
  field(:line_config, 8, type: FigKiwi.Schema.LineConfig, source_name: "lineConfig")

  field(:point_radius_config, 9,
    type: FigKiwi.Schema.PointRadiusConfig,
    source_name: "pointRadiusConfig"
  )

  field(:rotation3_d_config, 10,
    type: FigKiwi.Schema.Rotation3DConfig,
    source_name: "rotation3DConfig"
  )

  field(:circle_point_config, 11,
    type: FigKiwi.Schema.CirclePointConfig,
    source_name: "circlePointConfig"
  )

  field(:color_point_config, 12,
    type: FigKiwi.Schema.ColorPointConfig,
    source_name: "colorPointConfig"
  )

  field(:show_divider_above, 13, type: :bool, source_name: "showDividerAbove")
end
