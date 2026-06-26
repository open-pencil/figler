defmodule FigKiwi.Schema.Gradient do
  @moduledoc "Generated Kiwi message module for `Gradient`."
  use KiwiCodec, kind: :message
  field(:stops, 1, repeated: true, type: FigKiwi.Schema.GradientStop, source_name: "stops")
end
