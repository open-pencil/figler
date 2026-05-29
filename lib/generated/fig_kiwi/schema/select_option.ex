defmodule FigKiwi.Schema.SelectOption do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:value, 1, type: FigKiwi.Schema.VariableData, source_name: "value")
  field(:label, 2, type: :string, source_name: "label")
end
