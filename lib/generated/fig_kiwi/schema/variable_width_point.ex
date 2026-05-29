defmodule FigKiwi.Schema.VariableWidthPoint do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:position, 1, type: :float, source_name: "position")
  field(:ascent, 2, type: :float, source_name: "ascent")
  field(:descent, 3, type: :float, source_name: "descent")
  field(:segment_id, 4, type: :int, source_name: "segmentId")
end
