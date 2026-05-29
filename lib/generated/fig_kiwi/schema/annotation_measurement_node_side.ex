defmodule FigKiwi.Schema.AnnotationMeasurementNodeSide do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:top, 0)
  enum_value(:bottom, 1)
  enum_value(:left, 2)
  enum_value(:right, 3)
end
