defmodule Figler.Schema.Effect do
  @moduledoc "Generated Kiwi message module for `Effect`."
  use KiwiCodec, kind: :message
  field(:type, 1, type: {:enum, Figler.Schema.EffectType}, source_name: "type")
  field(:offset, 3, type: Figler.Schema.Vector, source_name: "offset")
  field(:radius, 4, type: :float, source_name: "radius")
  field(:visible, 5, type: :bool, source_name: "visible")
  field(:blend_mode, 6, type: {:enum, Figler.Schema.BlendMode}, source_name: "blendMode")
  field(:spread, 7, type: :float, source_name: "spread")
  field(:show_shadow_behind_node, 8, type: :bool, source_name: "showShadowBehindNode")
  field(:radius_var, 9, type: Figler.Schema.VariableData, source_name: "radiusVar")
  field(:color_var, 10, type: Figler.Schema.VariableData, source_name: "colorVar")
  field(:spread_var, 11, type: Figler.Schema.VariableData, source_name: "spreadVar")
  field(:x_var, 12, type: Figler.Schema.VariableData, source_name: "xVar")
  field(:y_var, 13, type: Figler.Schema.VariableData, source_name: "yVar")
  field(:count, 14, type: :uint, source_name: "count")
  field(:repeat_type, 15, type: {:enum, Figler.Schema.RepeatType}, source_name: "repeatType")
  field(:axis, 16, type: {:enum, Figler.Schema.EffectAxis}, source_name: "axis")
  field(:unit_type, 17, type: {:enum, Figler.Schema.UnitType}, source_name: "unitType")
  field(:order, 18, type: {:enum, Figler.Schema.RepeatOrder}, source_name: "order")
  field(:blur_op_type, 19, type: {:enum, Figler.Schema.BlurOpType}, source_name: "blurOpType")
  field(:start_offset, 20, type: Figler.Schema.Vector, source_name: "startOffset")
  field(:end_offset, 28, type: Figler.Schema.Vector, source_name: "endOffset")
  field(:start_radius, 21, type: :float, source_name: "startRadius")
  field(:color, 2, type: Figler.Schema.Color, source_name: "color")
  field(:secondary_color, 24, type: Figler.Schema.Color, source_name: "secondaryColor")
  field(:noise_size, 22, type: Figler.Schema.Vector, source_name: "noiseSize")
  field(:seed, 29, type: :uint, source_name: "seed")
  field(:clip_to_shape, 23, type: :bool, source_name: "clipToShape")
  field(:density, 25, type: :float, source_name: "density")
  field(:noise_type, 26, type: {:enum, Figler.Schema.NoiseType}, source_name: "noiseType")
  field(:opacity, 27, type: :float, source_name: "opacity")
  field(:refraction_radius, 30, type: :float, source_name: "refractionRadius")
  field(:specular_angle, 31, type: :float, source_name: "specularAngle")
  field(:specular_intensity, 32, type: :float, source_name: "specularIntensity")
  field(:bevel_size, 33, type: :float, source_name: "bevelSize")
  field(:chromatic_aberration, 34, type: :float, source_name: "chromaticAberration")
  field(:reflection_distance, 35, type: :float, source_name: "reflectionDistance")
  field(:refraction_intensity, 36, type: :float, source_name: "refractionIntensity")

  field(:refraction_radius_var, 37,
    type: Figler.Schema.VariableData,
    source_name: "refractionRadiusVar"
  )

  field(:specular_angle_var, 38,
    type: Figler.Schema.VariableData,
    source_name: "specularAngleVar"
  )

  field(:specular_intensity_var, 39,
    type: Figler.Schema.VariableData,
    source_name: "specularIntensityVar"
  )

  field(:chromatic_aberration_var, 40,
    type: Figler.Schema.VariableData,
    source_name: "chromaticAberrationVar"
  )

  field(:splay_var, 41, type: Figler.Schema.VariableData, source_name: "splayVar")

  field(:refraction_intensity_var, 42,
    type: Figler.Schema.VariableData,
    source_name: "refractionIntensityVar"
  )

  field(:custom_effect_id, 43, type: Figler.Schema.CodeComponentId, source_name: "customEffectId")

  field(:component_prop_assignments, 44,
    repeated: true,
    type: Figler.Schema.ComponentPropAssignment,
    source_name: "componentPropAssignments"
  )

  field(:start_radius_var, 45, type: Figler.Schema.VariableData, source_name: "startRadiusVar")
  field(:start_offset_x_var, 46, type: Figler.Schema.VariableData, source_name: "startOffsetXVar")
  field(:start_offset_y_var, 47, type: Figler.Schema.VariableData, source_name: "startOffsetYVar")
  field(:end_offset_x_var, 48, type: Figler.Schema.VariableData, source_name: "endOffsetXVar")
  field(:end_offset_y_var, 49, type: Figler.Schema.VariableData, source_name: "endOffsetYVar")
  field(:noise_size_x_var, 50, type: Figler.Schema.VariableData, source_name: "noiseSizeXVar")
  field(:noise_size_y_var, 51, type: Figler.Schema.VariableData, source_name: "noiseSizeYVar")
  field(:density_var, 52, type: Figler.Schema.VariableData, source_name: "densityVar")

  field(:effect_opacity_var, 53,
    type: Figler.Schema.VariableData,
    source_name: "effectOpacityVar"
  )

  field(:secondary_color_var, 54,
    type: Figler.Schema.VariableData,
    source_name: "secondaryColorVar"
  )

  field(:id, 55, type: Figler.Schema.GUID, source_name: "id")
end
