defmodule FigKiwi.Schema.KeyframeValueData do
  @moduledoc "Generated Kiwi message module for `KeyframeValueData`."
  use KiwiCodec, kind: :message
  field(:value, 1, type: FigKiwi.Schema.KeyframeAnyValue, source_name: "value")
  field(:value_type, 2, type: {:enum, FigKiwi.Schema.KeyframeValueType}, source_name: "valueType")
end
