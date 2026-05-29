defmodule FigKiwi.Schema.TransformFnValue do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:matrix3d, 1, type: FigKiwi.Schema.Matrix4f, source_name: "matrix3d")
  field(:perspective, 2, type: :float, source_name: "perspective")
  field(:rotate_angle, 3, type: :float, source_name: "rotateAngle")
  field(:translate_value, 4, type: :float, source_name: "translateValue")
end
