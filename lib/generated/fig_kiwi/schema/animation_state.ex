defmodule FigKiwi.Schema.AnimationState do
  @moduledoc "Generated Kiwi message module for `AnimationState`."
  use KiwiCodec, kind: :message
  field(:opacity, 1, type: :float, source_name: "opacity")
  field(:transform, 2, type: FigKiwi.Schema.Matrix, source_name: "transform")
end
