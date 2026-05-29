defmodule FigKiwi.Schema.ARIAAttributeData do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:type, 1, type: {:enum, FigKiwi.Schema.ARIAAttributeDataType}, source_name: "type")
  field(:value, 2, type: FigKiwi.Schema.ARIAAttributeAnyValue, source_name: "value")
end
