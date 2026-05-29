defmodule FigKiwi.Schema.StateGroupPropertyValueOrder do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:property, 1, type: :string, source_name: "property")
  field(:values, 2, repeated: true, type: :string, source_name: "values")
end
