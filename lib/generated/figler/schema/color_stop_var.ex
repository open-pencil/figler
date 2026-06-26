defmodule Figler.Schema.ColorStopVar do
  @moduledoc "Generated Kiwi message module for `ColorStopVar`."
  use KiwiCodec, kind: :message
  field(:color, 1, type: Figler.Schema.Color, source_name: "color")
  field(:color_var, 2, type: Figler.Schema.VariableData, source_name: "colorVar")
  field(:position, 3, type: :float, source_name: "position")
end
