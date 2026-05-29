defmodule FigKiwi.Schema.ExportSettings do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:suffix, 1, type: :string, source_name: "suffix")
  field(:image_type, 2, type: {:enum, FigKiwi.Schema.ImageType}, source_name: "imageType")
  field(:constraint, 3, type: FigKiwi.Schema.ExportConstraint, source_name: "constraint")
  field(:svg_data_name, 4, type: :bool, source_name: "svgDataName")
  field(:svg_id_mode, 5, type: {:enum, FigKiwi.Schema.ExportSVGIDMode}, source_name: "svgIDMode")
  field(:svg_outline_text, 6, type: :bool, source_name: "svgOutlineText")
  field(:contents_only, 7, type: :bool, source_name: "contentsOnly")
  field(:svg_force_stroke_masks, 8, type: :bool, source_name: "svgForceStrokeMasks")
  field(:use_absolute_bounds, 9, type: :bool, source_name: "useAbsoluteBounds")

  field(:color_profile, 10,
    type: {:enum, FigKiwi.Schema.ExportColorProfile},
    source_name: "colorProfile"
  )

  field(:quality, 11, type: :float, source_name: "quality")
  field(:use_bicubic_sampler, 12, type: :bool, source_name: "useBicubicSampler")
  field(:frame_rate, 13, type: :int, source_name: "frameRate")
  field(:loop_count, 14, type: :int, source_name: "loopCount")

  field(:background_type, 15,
    type: {:enum, FigKiwi.Schema.ExportBackgroundType},
    source_name: "backgroundType"
  )
end
