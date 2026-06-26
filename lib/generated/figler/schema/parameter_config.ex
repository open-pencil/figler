defmodule Figler.Schema.ParameterConfig do
  @moduledoc "Generated Kiwi message module for `ParameterConfig`."
  use KiwiCodec, kind: :message

  field(:number_prop_config, 1,
    type: Figler.Schema.NumberPropConfig,
    source_name: "numberPropConfig"
  )

  field(:control, 2, type: {:enum, Figler.Schema.ParameterConfigControl}, source_name: "control")
  field(:slider_config, 3, type: Figler.Schema.SliderConfig, source_name: "sliderConfig")
  field(:label, 4, type: Figler.Schema.VariableData, source_name: "label")
  field(:input_config, 5, type: Figler.Schema.InputConfig, source_name: "inputConfig")
  field(:select_config, 6, type: Figler.Schema.SelectConfig, source_name: "selectConfig")
  field(:point_config, 7, type: Figler.Schema.PointConfig, source_name: "pointConfig")
  field(:line_config, 8, type: Figler.Schema.LineConfig, source_name: "lineConfig")

  field(:point_radius_config, 9,
    type: Figler.Schema.PointRadiusConfig,
    source_name: "pointRadiusConfig"
  )

  field(:rotation3_d_config, 10,
    type: Figler.Schema.Rotation3DConfig,
    source_name: "rotation3DConfig"
  )

  field(:circle_point_config, 11,
    type: Figler.Schema.CirclePointConfig,
    source_name: "circlePointConfig"
  )

  field(:color_point_config, 12,
    type: Figler.Schema.ColorPointConfig,
    source_name: "colorPointConfig"
  )

  field(:show_divider_above, 13, type: :bool, source_name: "showDividerAbove")
end
