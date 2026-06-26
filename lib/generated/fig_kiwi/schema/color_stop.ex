defmodule FigKiwi.Schema.ColorStop do
  @moduledoc "Generated Kiwi struct module for `ColorStop`."
  use KiwiCodec, kind: :struct
  field(:color, 1, type: FigKiwi.Schema.Color, source_name: "color")
  field(:position, 2, type: :float, source_name: "position")
end
