defmodule FigKiwi.Schema.KeyframeValueData do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:value, 1, type: FigKiwi.Schema.KeyframeAnyValue, source_name: "value")
  field(:value_type, 2, type: {:enum, FigKiwi.Schema.KeyframeValueType}, source_name: "valueType")
end
