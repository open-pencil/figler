defmodule FigKiwi.Schema.Scene3d do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:perspective, 1, type: :float, source_name: "perspective")

  field(:perspective_origin, 2,
    type: FigKiwi.Schema.NumberVector2D,
    source_name: "perspectiveOrigin"
  )

  field(:preserve3d, 3, type: :bool, source_name: "preserve3d")
end
