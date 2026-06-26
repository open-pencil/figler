defmodule Figler.Schema.KeyframeValueData do
  @moduledoc "Generated Kiwi message module for `KeyframeValueData`."
  use KiwiCodec, kind: :message
  field(:value, 1, type: Figler.Schema.KeyframeAnyValue, source_name: "value")
  field(:value_type, 2, type: {:enum, Figler.Schema.KeyframeValueType}, source_name: "valueType")
end
