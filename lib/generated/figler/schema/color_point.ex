defmodule Figler.Schema.ColorPoint do
  @moduledoc "Generated Kiwi message module for `ColorPoint`."
  use KiwiCodec, kind: :message
  field(:point, 1, type: Figler.Schema.Vector, source_name: "point")
  field(:color, 2, type: Figler.Schema.VariableData, source_name: "color")
end
