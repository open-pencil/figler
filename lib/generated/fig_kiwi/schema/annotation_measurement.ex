defmodule FigKiwi.Schema.AnnotationMeasurement do
  @moduledoc "Generated Kiwi message module for `AnnotationMeasurement`."
  use KiwiCodec, kind: :message
  field(:id, 1, type: FigKiwi.Schema.GUID, source_name: "id")
  field(:from_node, 2, type: FigKiwi.Schema.GUID, source_name: "fromNode")
  field(:to_node, 3, type: FigKiwi.Schema.GUID, source_name: "toNode")

  field(:from_node_side, 4,
    type: {:enum, FigKiwi.Schema.AnnotationMeasurementNodeSide},
    source_name: "fromNodeSide"
  )

  field(:to_same_side, 5, type: :bool, source_name: "toSameSide")
  field(:inner_offset_relative, 6, type: :float, source_name: "innerOffsetRelative")
  field(:outer_offset_fixed, 7, type: :float, source_name: "outerOffsetFixed")
  field(:to_node_stable_path, 8, type: FigKiwi.Schema.GUIDPath, source_name: "toNodeStablePath")
  field(:free_text, 9, type: :string, source_name: "freeText")
end
