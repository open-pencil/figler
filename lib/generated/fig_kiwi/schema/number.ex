defmodule FigKiwi.Schema.Number do
  @moduledoc false
  use KiwiCodec, kind: :struct
  field(:value, 1, type: :float, source_name: "value")
  field(:units, 2, type: {:enum, FigKiwi.Schema.NumberUnits}, source_name: "units")
end
