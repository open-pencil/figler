defmodule FigKiwi.Schema.ScatterStrokeSettings do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:gap, 1, type: :float, source_name: "gap")
  field(:wiggle, 2, type: :float, source_name: "wiggle")
  field(:angular_jitter, 3, type: :float, source_name: "angularJitter")
  field(:rotation, 4, type: :float, source_name: "rotation")
  field(:size_jitter, 5, type: :float, source_name: "sizeJitter")
end
