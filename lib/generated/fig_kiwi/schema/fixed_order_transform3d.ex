defmodule FigKiwi.Schema.FixedOrderTransform3d do
  @moduledoc "Generated Kiwi message module for `FixedOrderTransform3d`."
  use KiwiCodec, kind: :message
  field(:perspective, 1, type: :float, source_name: "perspective")
  field(:translate_z, 2, type: :float, source_name: "translateZ")
  field(:rotate_x, 3, type: :float, source_name: "rotateX")
  field(:rotate_y, 4, type: :float, source_name: "rotateY")
  field(:rotate_z, 5, type: :float, source_name: "rotateZ")
end
