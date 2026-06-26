defmodule FigKiwi.Schema.ExportConstraint do
  @moduledoc "Generated Kiwi struct module for `ExportConstraint`."
  use KiwiCodec, kind: :struct
  field(:type, 1, type: {:enum, FigKiwi.Schema.ExportConstraintType}, source_name: "type")
  field(:value, 2, type: :float, source_name: "value")
end
