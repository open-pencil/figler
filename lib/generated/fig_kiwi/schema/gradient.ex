defmodule FigKiwi.Schema.Gradient do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:stops, 1, repeated: true, type: FigKiwi.Schema.GradientStop, source_name: "stops")
end
