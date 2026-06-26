defmodule FigKiwi.Schema.Paint do
  @moduledoc "Generated Kiwi message module for `Paint`."
  use KiwiCodec, kind: :message
  field(:type, 1, type: {:enum, FigKiwi.Schema.PaintType}, source_name: "type")
  field(:color, 2, type: FigKiwi.Schema.Color, source_name: "color")
  field(:opacity, 3, type: :float, source_name: "opacity")
  field(:visible, 4, type: :bool, source_name: "visible")
  field(:blend_mode, 5, type: {:enum, FigKiwi.Schema.BlendMode}, source_name: "blendMode")
  field(:stops, 6, repeated: true, type: FigKiwi.Schema.ColorStop, source_name: "stops")
  field(:transform, 7, type: FigKiwi.Schema.Matrix, source_name: "transform")
  field(:image, 8, type: FigKiwi.Schema.Image, source_name: "image")
  field(:image_thumbnail, 9, type: FigKiwi.Schema.Image, source_name: "imageThumbnail")
  field(:animated_image, 16, type: FigKiwi.Schema.Image, source_name: "animatedImage")
  field(:animation_frame, 17, type: :uint, source_name: "animationFrame")

  field(:image_scale_mode, 10,
    type: {:enum, FigKiwi.Schema.ImageScaleMode},
    source_name: "imageScaleMode"
  )

  field(:image_should_color_manage, 22, type: :bool, source_name: "imageShouldColorManage")
  field(:rotation, 11, type: :float, source_name: "rotation")
  field(:scale, 12, type: :float, source_name: "scale")

  field(:filter_color_adjust, 13,
    type: FigKiwi.Schema.FilterColorAdjust,
    source_name: "filterColorAdjust"
  )

  field(:paint_filter, 14, type: FigKiwi.Schema.PaintFilterMessage, source_name: "paintFilter")
  field(:emoji_code_points, 15, repeated: true, type: :uint, source_name: "emojiCodePoints")
  field(:video, 18, type: FigKiwi.Schema.Video, source_name: "video")
  field(:original_image_width, 19, type: :uint, source_name: "originalImageWidth")
  field(:original_image_height, 20, type: :uint, source_name: "originalImageHeight")
  field(:opacity_var, 38, type: FigKiwi.Schema.VariableData, source_name: "opacityVar")
  field(:color_var, 21, type: FigKiwi.Schema.VariableData, source_name: "colorVar")
  field(:image_var, 31, type: FigKiwi.Schema.VariableData, source_name: "imageVar")

  field(:stops_var, 23,
    repeated: true,
    type: FigKiwi.Schema.ColorStopVar,
    source_name: "stopsVar"
  )

  field(:thumb_hash_base64, 24, type: :string, source_name: "thumbHashBase64")
  field(:thumb_hash, 25, repeated: true, type: :byte, source_name: "thumbHash")
  field(:source_node_id, 26, type: FigKiwi.Schema.GUID, source_name: "sourceNodeId")
  field(:spacing, 27, type: :float, source_name: "spacing")
  field(:pattern_spacing, 37, type: FigKiwi.Schema.Vector, source_name: "patternSpacing")

  field(:pattern_tile_type, 28,
    type: {:enum, FigKiwi.Schema.PatternTileType},
    source_name: "patternTileType"
  )

  field(:vertical_alignment, 29,
    type: {:enum, FigKiwi.Schema.PatternAlignment},
    source_name: "verticalAlignment"
  )

  field(:horizontal_alignment, 30,
    type: {:enum, FigKiwi.Schema.PatternAlignment},
    source_name: "horizontalAlignment"
  )

  field(:id, 32, type: FigKiwi.Schema.GUID, source_name: "id")
  field(:alt_text, 33, type: :string, source_name: "altText")
  field(:noise_type, 34, type: {:enum, FigKiwi.Schema.NoiseType}, source_name: "noiseType")
  field(:density, 35, type: :float, source_name: "density")
  field(:noise_size, 36, type: FigKiwi.Schema.Vector, source_name: "noiseSize")

  field(:custom_effect_id, 39,
    type: FigKiwi.Schema.CodeComponentId,
    source_name: "customEffectId"
  )

  field(:component_prop_assignments, 40,
    repeated: true,
    type: FigKiwi.Schema.ComponentPropAssignment,
    source_name: "componentPropAssignments"
  )

  field(:interpolation_color_space, 41,
    type: {:enum, FigKiwi.Schema.InterpolationColorSpace},
    source_name: "interpolationColorSpace"
  )

  field(:interpolation_hue_method, 42,
    type: {:enum, FigKiwi.Schema.InterpolationHueMethod},
    source_name: "interpolationHueMethod"
  )
end
